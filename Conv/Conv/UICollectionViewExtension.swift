//
//  UICollectionViewExtension.swift
//  ConvExample
//
//  Created by Yudai.Hirose on 2018/04/25.
//  Copyright © 2018年 廣瀬雄大. All rights reserved.
//

import UIKit
import ObjectiveC

public extension UICollectionView {
    public func conv() -> Conv {
        let conv = Conv()
        switch (oldConv, newConv) {
        case (nil, _):
            self.oldConv = conv
        case (_, _):
            self.newConv = conv
        }
        return conv
    }
    
    public func conv(scrollViewDelegate: UIScrollViewDelegate?) -> Conv {
        let conv = self.conv()
        conv.scrollViewDelegate = scrollViewDelegate
        return conv
    }
    
    func shiftConv() {
        if let newConv = self.newConv {
            self.newConv = nil
            oldConv?.sections = newConv.sections
        }
    }
    
    public func reload() {
        guard let newConv = newConv else {
            print(" --------- call reloadData ----------- ")
            reloadData()
            return
        }
        
        let oldSections: [Section] = oldConv?.sections ?? []
        let newSections: [Section] = newConv.sections
        
        let operationSet = diffSection(from: oldSections, new: newSections)
        
        let itemDelete = operationSet.itemDelete.map { $0.indexPath }
        let itemInsert = operationSet.itemInsert.map { $0.indexPath }
        let itemMove = operationSet.itemMove
        let itemUpdate = operationSet.itemUpdate.map { $0.indexPath }
        
        let sectionDelete = operationSet.sectionDelete
        let sectionInsert = operationSet.sectionInsert
        let sectionMove = operationSet.sectionMove
        let sectionUpdate = operationSet.sectionUpdate
        
        first: do {
            sectionDelete.reversed().forEach {
                oldConv?.sections.remove(at: $0)
            }
            itemDelete.reversed().forEach {
                oldConv?.sections[$0.section].remove(at: $0.item)
            }
            performBatchUpdates({
                if !sectionDelete.isEmpty {
                    print(" --------- call deleteSections ----------- ")
                    print("\(sectionDelete)")
                    deleteSections(IndexSet(sectionDelete))
                }
                if !itemDelete.isEmpty {
                    print(" --------- call deleteItems ----------- ")
                    print("\(itemDelete)")
                    deleteItems(at: itemDelete)
                }
                if !itemUpdate.isEmpty {
                    print(" --------- call reloadItems ----------- ")
                    print("\(itemUpdate)")
                    reloadItems(at: itemUpdate)
                }
            })
        }
        
        second: do {
            sectionInsert.forEach {
                oldConv?.sections.insert(newConv.sections[$0], at: $0)
            }
            sectionMove.forEach {
                print("$0.source: \($0.source)")
                print("$0.target: \($0.target)")

                if let section = oldConv?.sections.remove(at: $0.source) {
                    oldConv?.sections.insert(section, at: $0.target)
                }
            }
            
            performBatchUpdates({
                if !sectionInsert.isEmpty {
                    print(" --------- call insertSections ----------- ")
                    print("\(sectionInsert)")
                    insertSections(IndexSet(sectionInsert))
                }
                if !sectionMove.isEmpty {
                    sectionMove.forEach {
                        print(" --------- call moveSection ----------- ")
                        print("source: \($0.source), target: \($0.target)")
                        moveSection($0.source, toSection: $0.target)
                    }
                }
            })
        }
        
        print(" --------- step third ----------- ")
        third: do {
            itemInsert.forEach {
                oldConv?.sections[$0.section].insert(newConv.sections[$0.section].items[$0.item], to: $0.item)
            }
            
            itemMove.forEach {
                print("$0.source: \($0.source.differenceIdentifier)")
                print("$0.target: \($0.target.differenceIdentifier)")
                
                if let item = oldConv?.sections[$0.source.indexPath.section].remove(at: $0.source.indexPath.item) {
                    oldConv?.sections[$0.target.indexPath.section].insert(item, to: $0.target.indexPath.item)
                }
            }
            
            print("oldConv.sections.count: \(oldConv!.sections.count)")
            oldConv?.sections.enumerated().forEach {
                print("items.offset: \($0.0)")
                print("items.count: \($0.1.items.count)")
            }

            performBatchUpdates({
                if !itemInsert.isEmpty {
                    print(" --------- call insertItems ----------- ")
                    print("\(itemInsert)")
                    insertItems(at: itemInsert)
                }
                if !itemMove.isEmpty {
                    itemMove.forEach {
                        print(" --------- call moveItem ----------- ")
                        print("source: \($0.source.indexPath), target: \($0.target.indexPath)")
                        moveItem(at: $0.source.indexPath, to: $0.target.indexPath)
                    }
                }
            })
        }
        
        print(" --------- step fourth ----------- ")
        fourth: do {
            shiftConv()
            performBatchUpdates({
                if !sectionUpdate.isEmpty {
                    print(" --------- call reloadSections ----------- ")
                    print("\(sectionUpdate)")
                    reloadSections(IndexSet(sectionUpdate))
                }
            })
        }
    }
}

fileprivate struct UICollectionViewAssociatedObjectHandle {
    static var oldConvKey: UInt8 = 0
    static var newConvKey: UInt8 = 0
}

extension UICollectionView {
    var oldConv: Conv? {
        set {
            dataSource = newValue
            delegate = newValue
            newValue?.collectionView = self
            
            objc_setAssociatedObject(self, &UICollectionViewAssociatedObjectHandle.oldConvKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &UICollectionViewAssociatedObjectHandle.oldConvKey) as? Conv
        }
    }
    
    var newConv: Conv? {
        set {
            newValue?.collectionView = self
            
            objc_setAssociatedObject(self, &UICollectionViewAssociatedObjectHandle.newConvKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &UICollectionViewAssociatedObjectHandle.newConvKey) as? Conv
        }
    }
}

