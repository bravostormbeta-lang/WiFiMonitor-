import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: root

    width: 1200
    height: 850

    minimumWidth: 900
    minimumHeight: 700

    visible: true
    title: "WiFi Monitor"

    color: "#090a0c"

    ScrollView {
        anchors.fill: parent
        clip: true

        ScrollBar.vertical.policy: ScrollBar.AsNeeded
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        Column {
            id: dashboard

            width: Math.max(root.width - 40, 860)

            anchors.horizontalCenter: parent.horizontalCenter

            topPadding: 28
            bottomPadding: 40

            spacing: 18

            // =========================================================
            // HEADER
            // =========================================================

            Row {
                width: parent.width

                spacing: 16

                Column {
                    width: parent.width - statusCard.width - 16

                    spacing: 5

                    Text {
                        text: "WiFi Monitor"

                        color: "#f5f5f7"

                        font.pixelSize: 32
                        font.bold: true
                    }

                    Text {
                        text: wifiController.connected
                              ? wifiController.ssid
                              : "No active Wi-Fi connection"

                        color: "#777b84"

                        font.pixelSize: 15
                    }
                }

                Rectangle {
                    id: statusCard

                    width: 180
                    height: 54

                    radius: 14

                    color: wifiController.connected
                           ? "#241012"
                           : "#151619"

                    border.width: 1

                    border.color: wifiController.connected
                                   ? "#7f2527"
                                   : "#292c32"

                    Row {
                        anchors.centerIn: parent

                        spacing: 9

                        Rectangle {
                            width: 10
                            height: 10

                            radius: 5

                            anchors.verticalCenter: parent.verticalCenter

                            color: wifiController.connected
                                   ? "#ff3b30"
                                   : "#5c6068"
                        }

                        Text {
                            text: wifiController.connected
                                  ? "CONNECTED"
                                  : "DISCONNECTED"

                            color: wifiController.connected
                                   ? "#ff6259"
                                   : "#777b84"

                            font.pixelSize: 13
                            font.bold: true

                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }


            // =========================================================
            // TOP METRICS
            // =========================================================

            Row {
                width: parent.width
                height: 185

                spacing: 14


                // =====================================================
                // SIGNAL
                // =====================================================

                Rectangle {
                    width: (parent.width - 28) / 3
                    height: parent.height

                    radius: 18

                    color: "#111318"

                    border.width: 1
                    border.color: "#25282e"

                    Column {
                        anchors.fill: parent

                        anchors.margins: 22

                        spacing: 8

                        Text {
                            text: "SIGNAL"

                            color: "#858992"

                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.4
                        }

                        Text {
                            text: wifiController.connected
                                  ? wifiController.signalStrength + " dBm"
                                  : "—"

                            color: "#f5f5f7"

                            font.pixelSize: 34
                            font.bold: true
                        }

                        Text {
                            text: wifiController.connected
                                  ? wifiController.signalQuality
                                  : "—"

                            color: wifiController.connected
                                   ? "#ff453a"
                                   : "#666a72"

                            font.pixelSize: 15
                            font.bold: true
                        }

                        Item {
                            width: 1
                            height: 8
                        }

                        Rectangle {
                            width: parent.width
                            height: 6

                            radius: 3

                            color: "#25282e"

                            Rectangle {
                                width: wifiController.connected
                                       ? Math.max(
                                             0,
                                             Math.min(
                                                 parent.width,
                                                 (wifiController.signalStrength + 90)
                                                 / 60
                                                 * parent.width
                                             )
                                         )
                                       : 0

                                height: parent.height

                                radius: 3

                                color: "#ff3b30"

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 300
                                    }
                                }
                            }
                        }
                    }
                }


                // =====================================================
                // SNR
                // =====================================================

                Rectangle {
                    width: (parent.width - 28) / 3
                    height: parent.height

                    radius: 18

                    color: "#111318"

                    border.width: 1
                    border.color: "#25282e"

                    Column {
                        anchors.fill: parent

                        anchors.margins: 22

                        spacing: 8

                        Text {
                            text: "SIGNAL-TO-NOISE"

                            color: "#858992"

                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.4
                        }

                        Text {
                            text: wifiController.connected
                                  ? wifiController.snr + " dB"
                                  : "—"

                            color: "#f5f5f7"

                            font.pixelSize: 34
                            font.bold: true
                        }

                        Text {
                            text: wifiController.connected
                                  ? wifiController.snrQuality
                                  : "—"

                            color: wifiController.connected
                                   ? "#ff453a"
                                   : "#666a72"

                            font.pixelSize: 15
                            font.bold: true
                        }

                        Item {
                            width: 1
                            height: 8
                        }

                        Rectangle {
                            width: parent.width
                            height: 6

                            radius: 3

                            color: "#25282e"

                            Rectangle {
                                width: wifiController.connected
                                       ? Math.max(
                                             0,
                                             Math.min(
                                                 parent.width,
                                                 wifiController.snr / 60
                                                 * parent.width
                                             )
                                         )
                                       : 0

                                height: parent.height

                                radius: 3

                                color: "#ff453a"

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 300
                                    }
                                }
                            }
                        }
                    }
                }


                // =====================================================
                // TRANSMIT RATE
                // =====================================================

                Rectangle {
                    width: (parent.width - 28) / 3
                    height: parent.height

                    radius: 18

                    color: "#111318"

                    border.width: 1
                    border.color: "#25282e"

                    Column {
                        anchors.fill: parent

                        anchors.margins: 22

                        spacing: 8

                        Text {
                            text: "TRANSMIT RATE"

                            color: "#858992"

                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.4
                        }

                        Text {
                            text: wifiController.connected
                                  ? Math.round(
                                        wifiController.transmitRate
                                    ) + " Mbps"
                                  : "—"

                            color: "#f5f5f7"

                            font.pixelSize: 34
                            font.bold: true
                        }

                        Text {
                            text: "Current PHY rate"

                            color: "#777b84"

                            font.pixelSize: 15
                        }

                        Item {
                            width: 1
                            height: 8
                        }

                        Text {
                            text: wifiController.connected
                                  ? wifiController.phyMode
                                  : "—"

                            color: "#c5c7cc"

                            font.pixelSize: 14
                        }
                    }
                }
            }


            // =========================================================
            // NETWORK
            // =========================================================

            Rectangle {
                width: parent.width
                height: 145

                radius: 18

                color: "#111318"

                border.width: 1
                border.color: "#25282e"

                Column {
                    anchors.fill: parent

                    anchors.margins: 20

                    spacing: 14

                    Text {
                        text: "NETWORK"

                        color: "#858992"

                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.4
                    }

                    Row {
                        width: parent.width

                        spacing: 40

                        Column {
                            width: parent.width / 2 - 20

                            spacing: 5

                            Text {
                                text: "SSID"

                                color: "#656971"

                                font.pixelSize: 12
                            }

                            Text {
                                text: wifiController.connected
                                      ? wifiController.ssid
                                      : "—"

                                color: "#f5f5f7"

                                font.pixelSize: 18
                                font.bold: true
                            }
                        }

                        Column {
                            width: parent.width / 2 - 20

                            spacing: 5

                            Text {
                                text: "BSSID"

                                color: "#656971"

                                font.pixelSize: 12
                            }

                            Text {
                                text: wifiController.connected
                                      ? wifiController.bssid
                                      : "—"

                                color: "#f5f5f7"

                                font.pixelSize: 18
                                font.bold: true
                            }
                        }
                    }
                }
            }


            // =========================================================
            // RADIO
            // =========================================================

            Rectangle {
                width: parent.width
                height: 135

                radius: 18

                color: "#111318"

                border.width: 1
                border.color: "#25282e"

                Column {
                    anchors.fill: parent

                    anchors.margins: 20

                    spacing: 14

                    Text {
                        text: "RADIO"

                        color: "#858992"

                        font.pixelSize: 12
                        font.bold: true
                        font.letterSpacing: 1.4
                    }

                    Row {
                        width: parent.width

                        spacing: 10

                        Repeater {
                            model: [
                                {
                                    label: "CHANNEL",
                                    value: wifiController.connected
                                           ? String(wifiController.channel)
                                           : "—"
                                },
                                {
                                    label: "BAND",
                                    value: wifiController.connected
                                           ? wifiController.band
                                           : "—"
                                },
                                {
                                    label: "PHY",
                                    value: wifiController.connected
                                           ? wifiController.phyMode
                                           : "—"
                                },
                                {
                                    label: "WIDTH",
                                    value: wifiController.connected
                                           ? wifiController.channelWidth
                                           : "—"
                                },
                                {
                                    label: "NOISE",
                                    value: wifiController.connected
                                           ? wifiController.noise + " dBm"
                                           : "—"
                                }
                            ]

                            delegate: Rectangle {
                                width: (parent.width - 40) / 5

                                height: 65

                                radius: 12

                                color: "#0c0e11"

                                border.width: 1
                                border.color: "#24272d"

                                Column {
                                    anchors.centerIn: parent

                                    spacing: 5

                                    Text {
                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text: modelData.label

                                        color: "#656971"

                                        font.pixelSize: 10
                                        font.bold: true
                                    }

                                    Text {
                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text: modelData.value

                                        color: "#e7e8eb"

                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }
            }


            // =========================================================
            // SIGNAL HISTORY
            // =========================================================

            Rectangle {
                width: parent.width
                height: 360

                radius: 18

                color: "#111318"

                border.width: 1
                border.color: "#25282e"

                Column {
                    anchors.fill: parent

                    anchors.margins: 20

                    spacing: 12

                    Row {
                        width: parent.width

                        Text {
                            text: "SIGNAL HISTORY"

                            color: "#858992"

                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.4
                        }

                        Item {
                            width: parent.width
                                   - parent.children[0].width
                                   - currentRssi.width

                            height: 1
                        }

                        Text {
                            id: currentRssi

                            text: wifiController.connected
                                  ? wifiController.signalStrength + " dBm"
                                  : "—"

                            color: "#f5f5f7"

                            font.pixelSize: 14
                            font.bold: true
                        }
                    }


                    Rectangle {
                        width: parent.width
                        height: 285

                        radius: 12

                        color: "#0c0e11"

                        border.width: 1
                        border.color: "#24272d"


                        // Grid
                        Column {
                            anchors.fill: parent

                            anchors.margins: 20

                            spacing: 0

                            Repeater {
                                model: 5

                                Rectangle {
                                    width: parent.width
                                    height: 1

                                    color: "#24272d"
                                }
                            }
                        }


                        // RSSI GRAPH
                        Canvas {
                            id: graph

                            anchors.fill: parent

                            anchors.margins: 20

                            property var values:
                                wifiController.rssiHistory

                            onValuesChanged:
                                requestPaint()

                            Connections {
                                target: wifiController

                                function onRssiHistoryChanged() {
                                    graph.requestPaint()
                                }
                            }

                            onPaint: {
                                var ctx = getContext("2d")

                                ctx.clearRect(
                                    0,
                                    0,
                                    width,
                                    height
                                )

                                if (!values ||
                                    values.length < 2)
                                    return

                                var minValue = -100
                                var maxValue = 0

                                ctx.beginPath()

                                for (var i = 0;
                                     i < values.length;
                                     i++) {

                                    var x =
                                        i *
                                        width /
                                        (values.length - 1)

                                    var normalized =
                                        (values[i] - minValue) /
                                        (maxValue - minValue)

                                    var y =
                                        height -
                                        normalized * height

                                    if (i === 0)
                                        ctx.moveTo(x, y)
                                    else
                                        ctx.lineTo(x, y)
                                }

                                ctx.strokeStyle = "#ff3b30"

                                ctx.lineWidth = 2

                                ctx.stroke()


                                // Current point
                                var last =
                                    values[values.length - 1]

                                var lastX = width

                                var lastNormalized =
                                    (last - minValue) /
                                    (maxValue - minValue)

                                var lastY =
                                    height -
                                    lastNormalized * height

                                ctx.beginPath()

                                ctx.arc(
                                    lastX,
                                    lastY,
                                    4,
                                    0,
                                    Math.PI * 2
                                )

                                ctx.fillStyle = "#ff453a"

                                ctx.fill()
                            }
                        }


                        Text {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom

                            anchors.leftMargin: 12
                            anchors.bottomMargin: 8

                            text: "60s ago"

                            color: "#5f636c"

                            font.pixelSize: 11
                        }

                        Text {
                            anchors.horizontalCenter:
                                parent.horizontalCenter

                            anchors.bottom: parent.bottom

                            anchors.bottomMargin: 8

                            text: "30s"

                            color: "#5f636c"

                            font.pixelSize: 11
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom

                            anchors.rightMargin: 12
                            anchors.bottomMargin: 8

                            text: "Now"

                            color: "#5f636c"

                            font.pixelSize: 11
                        }
                    }
                }
            }


            // =========================================================
            // FOOTER
            // =========================================================

            Text {
                width: parent.width

                text: "WiFi Monitor  •  CoreWLAN"

                horizontalAlignment: Text.AlignHCenter

                color: "#4e525a"

                font.pixelSize: 11
            }
        }
    }
}