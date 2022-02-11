//
//  FLNativeView.swift
//  flutter_platform_view_multi_tap_test
//
//  Created by Oren WANG on 2022/2/10.
//

import Flutter
import UIKit

class FLNativeViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FLNativeView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }
}

class FLNativeView: NSObject, FlutterPlatformView {
    private var _view: UIView

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        super.init()
        // iOS views can be created here
        createNativeView(view: _view)
    }

    func view() -> UIView {
        return _view
    }
    
    @objc
    func buttonClicked() {}

    func createNativeView(view _view: UIView){
        let button1 = UIButton(type: .system)
        button1.setTitle("Button 1", for: .normal)
        button1.frame = CGRect(x: 0, y: 0, width: 180, height: 48.0)
        button1.backgroundColor = UIColor.lightGray
        button1.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        _view.addSubview(button1)
        let button2 = UIButton(type: .system)
        button2.setTitle("Button 2", for: .normal)
        button2.frame = CGRect(x: 0, y: 100, width: 180, height: 48.0)
        button2.backgroundColor = UIColor.lightGray
        button2.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        _view.addSubview(button2)
    }
}

