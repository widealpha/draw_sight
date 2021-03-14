import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

//Path实体类
class PathEntity{
  List<Offset> points = <Offset>[];
  Paint paint = Paint()
    ..isAntiAlias = true
    ..strokeCap = StrokeCap.round
    ..color = Colors.black
    ..strokeWidth = 5.0;
}

class DrawPathPainter extends CustomPainter{
  final int maxPath;
  final List<PathEntity> paths;
  final List<PathEntity> holdPath;//保留用来保存图像，而不用调用endRecording
  List<Offset> points = <Offset>[];
  PictureRecorder holdPictureRecorder;//用于提取图片
  Canvas holdCanvas;
  Picture holdPicture;//用于保存提取的图片

  DrawPathPainter(this.paths,this.holdPath,this.maxPath);

  @override
  void paint(Canvas canvas, Size size) {
    ///当步数大于限制，绘制超出的在固化画布上，不能撤回，以节省内存
    ///对溢出path进行固化
    if(paths.length > maxPath){
      PathEntity overflowPath = paths.removeAt(0);//超过max溢出的path
      holdPath.add(overflowPath);
      holdCanvas = Canvas(holdPictureRecorder);
      if(holdPicture != null){
        holdCanvas.drawPicture(holdPicture);
      }
      points = overflowPath.points;
      for(int i = 0; i < points.length - 1; i++){
        if(points[i] != null && points[i + 1] != null ){
          holdCanvas.drawLine(points[i], points[i + 1], overflowPath.paint);
        }
      }
      holdPicture = holdPictureRecorder.endRecording();
      holdPictureRecorder = PictureRecorder();
    }
    if (holdPath.length == 0){
      holdPicture = null;
    } else if(holdPicture != null){
      canvas.drawPicture(holdPicture);
    }
      //绘制可撤销屏幕画板
    paths.forEach((path){
      points = path.points;
      for(int i = 0; i < points.length - 1; i++){
        if(points[i] != null && points[i + 1] != null ){
          canvas.drawLine(points[i], points[i + 1], path.paint);
        }
      }
    });
  }

  @override
  bool shouldRepaint(DrawPathPainter oldDelegate) {
    return oldDelegate.points != points;
  }

}

class Signature extends StatefulWidget{
  final Paint _mPaint;
  Signature(key,this._mPaint) : super(key:key);
  @override
  State<StatefulWidget> createState() {
    return SignatureState(_mPaint);
  }

}

class SignatureState extends State{
  final List<PathEntity> _paintedPaths = <PathEntity>[];
  final List<PathEntity> _revokedPaths = <PathEntity>[];
  final List<PathEntity> _holdPaths = <PathEntity>[];
  PathEntity _pathEntity;
  Paint _mPaint;
  List<Offset> points;
  bool isMoved;
  SignatureState(this._mPaint);

  @override
  void initState() {
    super.initState();
    _mPaint = _clonePaint(_mPaint);//初始化并克隆Paint
    _pathEntity = PathEntity();
    isMoved =  true;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        CustomPaint(
          painter: DrawPathPainter(_paintedPaths,_holdPaths,100),
          size: Size.infinite,
        ),
        GestureDetector(
          onPanDown: (DragDownDetails details){
            isMoved = false;
            _pathEntity = PathEntity();
            _pathEntity.paint = _clonePaint(_mPaint);
            setState(() {
              _paintedPaths.add(_pathEntity);
            });
          },
          onPanUpdate: (DragUpdateDetails details){
            RenderBox rendBox = context.findRenderObject();
            Offset localPosition = rendBox.globalToLocal(details.globalPosition);
            setState(() {
              isMoved = true;
              _pathEntity.points.add(localPosition);
            });
          },
          onPanEnd: (DragEndDetails details){
            _pathEntity.points.add(null);
            if(!isMoved){
              _paintedPaths.removeLast();
            } else{
              setState(() {
                _revokedPaths.clear();
              });
            }
          },
        ),
      ],
    );
  }
  Paint _clonePaint(Paint paint){
    Paint _clonePaint = Paint()
      ..isAntiAlias = paint.isAntiAlias
      ..strokeCap = paint.strokeCap
      ..strokeJoin = paint.strokeJoin
      ..filterQuality = paint.filterQuality
      ..color = Color(paint.color.value)
      ..strokeWidth = paint.strokeWidth
      ..blendMode = paint.blendMode;
    return _clonePaint;
  }

  void changePaint(Paint paint){
    _mPaint = _clonePaint(paint);
  }

  void clear(){
    setState(() {
      _holdPaths.clear();
      _paintedPaths.clear();
      _revokedPaths.clear();
    });
  }

  void undo(){
    setState(() {
      if(_paintedPaths.length > 0){
        _revokedPaths.add(_paintedPaths.removeLast());
      } else{
        Fluttertoast.showToast(msg: "撤销失败");
      }
    });
  }

  void redo(){
    setState(() {
      if(_revokedPaths.length > 0){
        _paintedPaths.add(_revokedPaths.removeLast());
      } else {
        Fluttertoast.showToast(msg: "反撤销失败");
      }
    });
  }

  void save() async{
    PictureRecorder _saveRecord = PictureRecorder();
    List<Offset> _savePoints = <Offset>[];
    Canvas _saveCanvas = Canvas(_saveRecord);
    Picture _savePic;
    _saveCanvas.drawColor(Colors.white, BlendMode.xor);
    _holdPaths.forEach((path){
      _savePoints = path.points;
      for(int i = 0; i < _savePoints.length - 1; i++){
        if(_savePoints[i] != null && _savePoints[i + 1] != null ){
          _saveCanvas.drawLine(_savePoints[i], _savePoints[i + 1], path.paint);
        }
      }
    });
    _paintedPaths.forEach((path){
      _savePoints = path.points;
      for(int i = 0; i < _savePoints.length - 1; i++){
        if(_savePoints[i] != null && _savePoints[i + 1] != null ){
          _saveCanvas.drawLine(_savePoints[i], _savePoints[i + 1], path.paint);
        }
      }
    });
    _savePic = _saveRecord.endRecording();
    var image = await _savePic.toImage(context.size.width.toInt(), context.size.height.toInt());
    ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
    try{
      final result = await ImageGallerySaver.saveImage(byteData.buffer.asUint8List());
      Fluttertoast.showToast(msg: "已保存到${result.toString()}");
    } catch(e){
      Fluttertoast.showToast(msg: "保存失败");
    }
  }
}

