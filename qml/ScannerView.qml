import Blockstream.Green
import QtMultimedia
import QtCore
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Shapes

Item {
    signal codeScanned(string code)
    signal bcurScanned(var result)
    function start() {
        if (permission.status === Qt.Granted) {
            camera.start()
        } else if (permission.status === Qt.Undetermined) {
            permission.request()
        }
    }

    id: self

    Component.onCompleted: self.start()

    CameraPermission {
        id: permission
        onStatusChanged: self.start()
    }

    BusyIndicator {
        anchors.centerIn: parent
        hoverEnabled: false
    }

    CaptureSession {
        camera: Camera {
            id: camera
        }
        videoOutput: video_output
    }

    VideoOutput {
        id: video_output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    Item {
        anchors.centerIn: self
        scale: Math.max(self.width / video_output.sourceRect.width, self.height / video_output.sourceRect.height)
        width: video_output.sourceRect.width
        height: video_output.sourceRect.height

        Repeater {
            model: detector.results
            delegate: Shape {
                ShapePath {
                    fillColor: Qt.alpha('#00B45A', 0.25)
                    startX: modelData.points[0].x
                    startY: modelData.points[0].y
                    strokeColor: Qt.alpha('#00B45A', 0.75)
                    strokeWidth: 10
                    joinStyle: ShapePath.RoundJoin
                    PathLine {
                        x: modelData.points[1].x
                        y: modelData.points[1].y
                    }
                    PathLine {
                        x: modelData.points[2].x
                        y: modelData.points[2].y
                    }
                    PathLine {
                        x: modelData.points[3].x
                        y: modelData.points[3].y
                    }
                    PathLine {
                        x: modelData.points[0].x
                        y: modelData.points[0].y
                    }
                }
            }
        }
    }
    ZXingDetector {
        id: detector
        videoSink: video_output.videoSink
        onResultsChanged: {
            for (const result of detector.results) {
                controller.process(result.text)
                // ignore remaining results
                break
            }
        }
    }
    BCURController {
        id: controller
        onResultDecoded: (result) => self.bcurScanned(result)
        onDataDiscarded: (data) => self.codeScanned(data)
    }

    TProgressBar {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 20
        from: 0
        opacity: 0.6
        to: 100
        visible: controller.progress > 0
        value: controller.progress
    }
}
