import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AndroidViewState {
  waitingForSize,
  creating,
  created,
  disposed,
}

class CustomSurfaceAndroidViewController implements AndroidViewController {
  CustomSurfaceAndroidViewController({
    required this.viewId,
    required String viewType,
    required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic>? creationParamsCodec,
    bool waitingForSize = false,
  })  : assert(creationParams == null || creationParamsCodec != null),
        _viewType = viewType,
        _layoutDirection = layoutDirection,
        _creationParams = creationParams,
        _creationParamsCodec = creationParamsCodec,
        _state = waitingForSize
            ? AndroidViewState.waitingForSize
            : AndroidViewState.creating;

  static const int kActionDown = 0;
  static const int kActionUp = 1;
  static const int kActionMove = 2;
  static const int kActionCancel = 3;
  static const int kActionPointerDown = 5;
  static const int kActionPointerUp = 6;
  static const int kAndroidLayoutDirectionLtr = 0;
  static const int kAndroidLayoutDirectionRtl = 1;
  @override
  final int viewId;

  final String _viewType;

  final _CustomAndroidMotionEventConverter _motionEventConverter =
      _CustomAndroidMotionEventConverter();

  TextDirection _layoutDirection;

  AndroidViewState _state;

  final dynamic _creationParams;

  final MessageCodec<dynamic>? _creationParamsCodec;

  final List<PlatformViewCreatedCallback> _platformViewCreatedCallbacks =
      <PlatformViewCreatedCallback>[];

  static int _getAndroidDirection(TextDirection direction) {
    switch (direction) {
      case TextDirection.ltr:
        return kAndroidLayoutDirectionLtr;
      case TextDirection.rtl:
        return kAndroidLayoutDirectionRtl;
    }
  }

  static int pointerAction(int pointerId, int action) {
    return ((pointerId << 8) & 0xff00) | (action & 0xff);
  }

  Future<void> _sendDisposeMessage() {
    return SystemChannels.platform_views
        .invokeMethod<void>('dispose', <String, dynamic>{
      'id': viewId,
      'hybrid': true,
    });
  }

  Future<void> _sendCreateMessage() {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': viewId,
      'viewType': _viewType,
      'direction': _getAndroidDirection(_layoutDirection),
      'hybrid': true,
    };
    if (_creationParams != null) {
      final ByteData paramsByteData =
          _creationParamsCodec!.encodeMessage(_creationParams)!;
      args['params'] = Uint8List.view(
        paramsByteData.buffer,
        0,
        paramsByteData.lengthInBytes,
      );
    }
    return SystemChannels.platform_views.invokeMethod<void>('create', args);
  }

  @override
  Future<void> create() async {
    assert(_state != AndroidViewState.disposed,
        'trying to create a disposed Android view');

    await _sendCreateMessage();

    _state = AndroidViewState.created;
    for (final PlatformViewCreatedCallback callback
        in _platformViewCreatedCallbacks) {
      callback(viewId);
    }
  }

  @override
  Future<void> setSize(Size size) {
    throw UnimplementedError(
        'Not supported for $SurfaceAndroidViewController.');
  }

  @override
  Future<void> sendMotionEvent(AndroidMotionEvent event) async {
    await SystemChannels.platform_views
        .invokeMethod<dynamic>('touch', <dynamic>[
      viewId,
      event.downTime,
      event.eventTime,
      event.action,
      event.pointerCount,
      event.pointerProperties
          .map<List<int>>(
              (AndroidPointerProperties p) => <int>[p.id, p.toolType])
          .toList(),
      event.pointerCoords
          .map<List<double>>((AndroidPointerCoords p) => <double>[
                p.orientation,
                p.pressure,
                p.size,
                p.toolMajor,
                p.toolMinor,
                p.touchMajor,
                p.touchMinor,
                p.x,
                p.y,
              ])
          .toList(),
      event.metaState,
      event.buttonState,
      event.xPrecision,
      event.yPrecision,
      event.deviceId,
      event.edgeFlags,
      event.source,
      event.flags,
      event.motionEventId,
    ]);
  }

  @override
  PointTransformer get pointTransformer =>
      _motionEventConverter._pointTransformer;
  @override
  set pointTransformer(PointTransformer transformer) {
    _motionEventConverter._pointTransformer = transformer;
  }

  @override
  bool get isCreated => _state == AndroidViewState.created;

  @override
  void addOnPlatformViewCreatedListener(PlatformViewCreatedCallback listener) {
    assert(_state != AndroidViewState.disposed);
    _platformViewCreatedCallbacks.add(listener);
  }

  @override
  void removeOnPlatformViewCreatedListener(
      PlatformViewCreatedCallback listener) {
    assert(_state != AndroidViewState.disposed);
    _platformViewCreatedCallbacks.remove(listener);
  }

  @override
  Future<void> setLayoutDirection(TextDirection layoutDirection) async {
    assert(
      _state != AndroidViewState.disposed,
      'trying to set a layout direction for a disposed UIView. View id: $viewId',
    );

    if (layoutDirection == _layoutDirection) return;

    _layoutDirection = layoutDirection;

    if (_state == AndroidViewState.waitingForSize) return;

    await SystemChannels.platform_views
        .invokeMethod<void>('setDirection', <String, dynamic>{
      'id': viewId,
      'direction': _getAndroidDirection(layoutDirection),
    });
  }

  @override
  Future<void> dispatchPointerEvent(PointerEvent event) async {
    if (event is PointerHoverEvent) {
      return;
    }

    if (event is PointerDownEvent) {
      _motionEventConverter.handlePointerDownEvent(event);
    }

    _motionEventConverter.updatePointerPositions(event);

    final AndroidMotionEvent? androidEvent =
        _motionEventConverter.toAndroidMotionEvent(event);

    if (event is PointerUpEvent) {
      _motionEventConverter.handlePointerUpEvent(event);
    } else if (event is PointerCancelEvent) {
      _motionEventConverter.handlePointerCancelEvent(event);
    }

    if (androidEvent != null) {
      await sendMotionEvent(androidEvent);
    }
  }

  @override
  Future<void> clearFocus() {
    if (_state != AndroidViewState.created) {
      return Future<void>.value();
    }
    return SystemChannels.platform_views
        .invokeMethod<void>('clearFocus', viewId);
  }

  @override
  Future<void> dispose() async {
    if (_state == AndroidViewState.creating ||
        _state == AndroidViewState.created) await _sendDisposeMessage();
    _platformViewCreatedCallbacks.clear();
    _state = AndroidViewState.disposed;

    // TODO. Below line is not implemented because the getter '_instance' isn't defined.
    // PlatformViewsService._instance._focusCallbacks.remove(viewId);
  }

  @override
  int get textureId {
    throw UnimplementedError(
        'Not supported for $SurfaceAndroidViewController.');
  }
}

class _CustomAndroidMotionEventConverter {
  _CustomAndroidMotionEventConverter();

  final Map<int, AndroidPointerCoords> pointerPositions =
      <int, AndroidPointerCoords>{};
  final Map<int, AndroidPointerProperties> pointerProperties =
      <int, AndroidPointerProperties>{};
  final Set<int> usedAndroidPointerIds = <int>{};

  // ignore: unnecessary_getters_setters
  PointTransformer get pointTransformer => _pointTransformer;
  late PointTransformer _pointTransformer;
  set pointTransformer(PointTransformer transformer) {
    _pointTransformer = transformer;
  }

  int? downTimeMillis;

  void handlePointerDownEvent(PointerDownEvent event) {
    if (pointerProperties.isEmpty) {
      downTimeMillis = event.timeStamp.inMilliseconds;
    }
    int androidPointerId = 0;
    while (usedAndroidPointerIds.contains(androidPointerId)) {
      androidPointerId++;
    }
    usedAndroidPointerIds.add(androidPointerId);
    pointerProperties[event.pointer] = propertiesFor(event, androidPointerId);
  }

  void updatePointerPositions(PointerEvent event) {
    final Offset position = _pointTransformer(event.position);
    pointerPositions[event.pointer] = AndroidPointerCoords(
      orientation: event.orientation,
      pressure: event.pressure,
      size: event.size,
      toolMajor: event.radiusMajor,
      toolMinor: event.radiusMinor,
      touchMajor: event.radiusMajor,
      touchMinor: event.radiusMinor,
      x: position.dx,
      y: position.dy,
    );
  }

  void _remove(int pointer) {
    pointerPositions.remove(pointer);
    usedAndroidPointerIds.remove(pointerProperties[pointer]!.id);
    pointerProperties.remove(pointer);
    if (pointerProperties.isEmpty) {
      downTimeMillis = null;
    }
  }

  void handlePointerUpEvent(PointerUpEvent event) {
    _remove(event.pointer);
  }

  void handlePointerCancelEvent(PointerCancelEvent event) {
    _remove(event.pointer);
  }

  AndroidMotionEvent? toAndroidMotionEvent(PointerEvent event) {
    final List<int> pointers = pointerPositions.keys.toList();
    final int pointerIdx = pointers.indexOf(event.pointer);
    final int numPointers = pointers.length;

    const int kPointerDataFlagBatched = 1;

    if (event.platformData == kPointerDataFlagBatched ||
        (isSinglePointerAction(event) && pointerIdx < numPointers - 1)) {
      return null;
    }

    final int action;
    if (event is PointerDownEvent) {
      action = numPointers == 1
          ? AndroidViewController.kActionDown
          : AndroidViewController.pointerAction(
              pointerIdx, AndroidViewController.kActionPointerDown);
    } else if (event is PointerUpEvent) {
      action = numPointers == 1
          ? AndroidViewController.kActionUp
          : AndroidViewController.pointerAction(
              pointerIdx, AndroidViewController.kActionPointerUp);
    } else if (event is PointerMoveEvent) {
      action = AndroidViewController.kActionMove;
    } else if (event is PointerCancelEvent) {
      action = AndroidViewController.kActionCancel;
    } else {
      return null;
    }

    return AndroidMotionEvent(
      downTime: downTimeMillis!,
      eventTime: event.timeStamp.inMilliseconds,
      action: action,
      pointerCount: pointerPositions.length,
      pointerProperties: pointers
          .map<AndroidPointerProperties>((int i) => pointerProperties[i]!)
          .toList(),
      pointerCoords: pointers
          .map<AndroidPointerCoords>((int i) => pointerPositions[i]!)
          .toList(),
      metaState: 0,
      buttonState: 0,
      xPrecision: 1.0,
      yPrecision: 1.0,
      deviceId: 0,
      edgeFlags: 0,
      source: 0,
      flags: 0,
      motionEventId: event.embedderId,
    );
  }

  AndroidPointerProperties propertiesFor(PointerEvent event, int pointerId) {
    int toolType = AndroidPointerProperties.kToolTypeUnknown;
    switch (event.kind) {
      case PointerDeviceKind.touch:
        toolType = AndroidPointerProperties.kToolTypeFinger;
        break;
      case PointerDeviceKind.mouse:
        toolType = AndroidPointerProperties.kToolTypeMouse;
        break;
      case PointerDeviceKind.stylus:
        toolType = AndroidPointerProperties.kToolTypeStylus;
        break;
      case PointerDeviceKind.invertedStylus:
        toolType = AndroidPointerProperties.kToolTypeEraser;
        break;
      case PointerDeviceKind.unknown:
        toolType = AndroidPointerProperties.kToolTypeUnknown;
        break;
    }
    return AndroidPointerProperties(id: pointerId, toolType: toolType);
  }

  bool isSinglePointerAction(PointerEvent event) =>
      event is! PointerDownEvent && event is! PointerUpEvent;
}
