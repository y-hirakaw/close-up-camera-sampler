接写でカメラを使う場合の実装方法のサンプルです。

* StandardCameraViewController
  * 特別なことは何もしていない普通のカメラです。
* CloseUpCameraViewController
  * 焦点距離に応じてズームを行い接写でもボケないようにします。スライダーでズーム倍率を変更できます。
* SwitchCameraViewController
  * 被写体との距離によってカメラを切り替えます。
* FocusCameraViewController
  * カメラプレビュー上をタップするとその位置にピントを合わせます。
