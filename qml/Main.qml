import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    width: 800
    height: 600

    visible: true

    title: "WiFi Monitor"

    Column {
        anchors.centerIn: parent

        spacing: 12

        Text {
            text: "WiFi Monitor"
            font.pixelSize: 32
        }

        Text {
            text: wifiController.connected
                  ? "● Connected"
                  : "● Not Connected"

            font.pixelSize: 22
        }

        Text {
            text: "Network: " +
                  (wifiController.connected
                   ? wifiController.ssid
                   : "—")

            font.pixelSize: 22
        }

        Text {
            text: "BSSID: " +
                  (wifiController.connected
                   ? wifiController.bssid
                   : "—")

            font.pixelSize: 22
        }

        Text {
            text: "RSSI: " +
                  (wifiController.connected
                   ? wifiController.signalStrength + " dBm"
                   : "—")

            font.pixelSize: 22
        }

        Text {
            text: "Noise: " +
                  (wifiController.connected
                   ? wifiController.noise + " dBm"
                   : "—")

            font.pixelSize: 22
        }

        Text {
            text: "Transmit Rate: " +
                  (wifiController.connected
                   ? wifiController.transmitRate + " Mbps"
                   : "—")

            font.pixelSize: 22
        }

        Text {
            text: "Channel: " +
                  (wifiController.connected
                   ? wifiController.channel
                   : "—")

            font.pixelSize: 22
        }

        Text {
            text: "Band: " +
                  (wifiController.connected
                   ? wifiController.band
                   : "—")

            font.pixelSize: 22
        }

        Text {
            text: "PHY: " +
                  (wifiController.connected
                   ? wifiController.phyMode
                   : "—")

            font.pixelSize: 22
        }

        Text {
            text: "Channel Width: " +
                  (wifiController.connected
                   ? wifiController.channelWidth
                   : "—")

            font.pixelSize: 22
        }
    }
}