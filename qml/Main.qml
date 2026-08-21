import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: root

    width: 1200
    height: 900

    minimumWidth: 950
    minimumHeight: 700

    visible: true
    title: "WiFi Monitor"

    color: background


    // =========================================================
    // THEME
    // =========================================================

    readonly property color background: "#090a0c"

    readonly property color card: "#111318"
    readonly property color cardInner: "#0c0e11"

    readonly property color border: "#25282e"
    readonly property color borderStrong: "#343840"

    readonly property color textPrimary: "#f5f5f7"
    readonly property color textSecondary: "#858992"
    readonly property color textMuted: "#5f636c"

    readonly property color red: "#ff3b30"
    readonly property color redBright: "#ff453a"
    readonly property color redDark: "#241012"

    readonly property color selectedRow: "#241012"


    // =========================================================
    // LIVE SCAN STATE
    // =========================================================

    property string lastScanTime: "--:--:--"

    property int scanUpdateNumber: 0

    property var previousRssiByBssid: ({})
    property var latestRssiByBssid: ({})

    property var previousSnrByBssid: ({})
    property var latestSnrByBssid: ({})


    // =========================================================
    // SELECTED NETWORK
    // =========================================================

    property var selectedNetworkData: null


    // =========================================================
    // HELPERS
    // =========================================================

    function signalPercentage(value) {

        var v = Number(value)

        if (isNaN(v))
            return 0

        var percentage =
            ((v + 90) / 60) * 100

        return Math.max(
            0,
            Math.min(
                100,
                percentage
            )
        )
    }


    function snrPercentage(value) {

        var v = Number(value)

        if (isNaN(v))
            return 0

        return Math.max(
            0,
            Math.min(
                100,
                (v / 70) * 100
            )
        )
    }


    function qualityColor(quality) {

        var q = String(quality)

        if (q === "Excellent")
            return redBright

        if (q === "Good")
            return red

        if (q === "Fair")
            return "#ff6b68"

        return textMuted
    }


    function findNetworkByBssid(bssid) {

        var networks =
            wifiController.nearbyNetworks

        if (!networks)
            return null

        var key =
            String(bssid)

        for (
            var i = 0;
            i < networks.length;
            ++i
        ) {

            if (
                String(networks[i].bssid) ===
                key
            ) {
                return networks[i]
            }
        }

        return null
    }


    function countBand(bandName) {

        var networks =
            wifiController.nearbyNetworks

        var count = 0

        if (!networks)
            return 0

        for (
            var i = 0;
            i < networks.length;
            ++i
        ) {

            if (
                String(networks[i].band) ===
                bandName
            ) {
                count++
            }
        }

        return count
    }


    // =========================================================
    // LIVE DELTAS
    // =========================================================

    function rssiDelta(bssid) {

        var key =
            String(bssid)

        if (
            previousRssiByBssid[key] === undefined ||
            latestRssiByBssid[key] === undefined
        ) {
            return 0
        }

        return Number(
            latestRssiByBssid[key]
        ) -
        Number(
            previousRssiByBssid[key]
        )
    }


    function snrDelta(bssid) {

        var key =
            String(bssid)

        if (
            previousSnrByBssid[key] === undefined ||
            latestSnrByBssid[key] === undefined
        ) {
            return 0
        }

        return Number(
            latestSnrByBssid[key]
        ) -
        Number(
            previousSnrByBssid[key]
        )
    }


    function deltaArrow(delta) {

        var value =
            Number(delta)

        if (value > 0)
            return "↑"

        if (value < 0)
            return "↓"

        return "—"
    }


    function deltaColor(delta) {

        var value =
            Number(delta)

        if (value > 0)
            return redBright

        if (value < 0)
            return "#ff6b68"

        return textMuted
    }


    function formatDelta(delta) {

        var value =
            Number(delta)

        if (value === 0)
            return ""

        return " " +
               Math.abs(
                   Math.round(value)
               )
    }


    // =========================================================
    // SELECT NETWORK
    // =========================================================

    function selectNetwork(network) {

        if (!network)
            return


        var bssid =
            String(network.bssid)


        wifiController.selectNetwork(
            bssid
        )


        selectedNetworkData = {

            ssid:
                String(network.ssid),

            bssid:
                bssid,

            signalStrength:
                Number(network.signalStrength),

            noise:
                Number(network.noise),

            snr:
                Number(network.snr),

            channel:
                Number(network.channel),

            band:
                String(network.band),

            channelWidth:
                String(network.channelWidth),

            signalQuality:
                String(network.signalQuality),

            snrQuality:
                String(network.snrQuality)
        }


        selectedRssiGraph.requestPaint()

        selectedSnrGraph.requestPaint()
    }


    // =========================================================
    // UPDATE SELECTED NETWORK
    // =========================================================

    function updateSelectedNetwork() {

        var selectedBssid =
            String(
                wifiController.selectedNetworkBssid
            )


        if (
            selectedBssid === ""
        ) {
            selectedNetworkData = null
            return
        }


        var network =
            findNetworkByBssid(
                selectedBssid
            )


        if (!network)
            return


        selectedNetworkData = {

            ssid:
                String(network.ssid),

            bssid:
                String(network.bssid),

            signalStrength:
                Number(network.signalStrength),

            noise:
                Number(network.noise),

            snr:
                Number(network.snr),

            channel:
                Number(network.channel),

            band:
                String(network.band),

            channelWidth:
                String(network.channelWidth),

            signalQuality:
                String(network.signalQuality),

            snrQuality:
                String(network.snrQuality)
        }


        selectedRssiGraph.requestPaint()

        selectedSnrGraph.requestPaint()
    }


    // =========================================================
    // LIVE SCAN UPDATE
    // =========================================================

    Connections {

        target:
            wifiController


        function onNearbyNetworksChanged() {

            var oldRssi =
                latestRssiByBssid

            var oldSnr =
                latestSnrByBssid


            var newRssi =
                ({})

            var newSnr =
                ({})

            var newPreviousRssi =
                ({})

            var newPreviousSnr =
                ({})


            var networks =
                wifiController.nearbyNetworks


            if (networks) {

                for (
                    var i = 0;
                    i < networks.length;
                    ++i
                ) {

                    var network =
                        networks[i]

                    var bssid =
                        String(network.bssid)


                    var currentRssi =
                        Number(
                            network.signalStrength
                        )

                    var currentSnr =
                        Number(
                            network.snr
                        )


                    if (
                        oldRssi[bssid] !== undefined
                    ) {

                        newPreviousRssi[bssid] =
                            oldRssi[bssid]
                    }


                    if (
                        oldSnr[bssid] !== undefined
                    ) {

                        newPreviousSnr[bssid] =
                            oldSnr[bssid]
                    }


                    newRssi[bssid] =
                        currentRssi

                    newSnr[bssid] =
                        currentSnr
                }
            }


            previousRssiByBssid =
                newPreviousRssi

            previousSnrByBssid =
                newPreviousSnr

            latestRssiByBssid =
                newRssi

            latestSnrByBssid =
                newSnr


            scanUpdateNumber++


            lastScanTime =
                new Date().toLocaleTimeString()


            updateSelectedNetwork()
        }
    }


    // =========================================================
    // CHANNEL INTELLIGENCE HELPERS
    // =========================================================

    function channelAnalysesForBand(bandName) {

        var analyses = wifiController.channelAnalyses

        var result = []

        if (!analyses)
            return result

        for (var i = 0; i < analyses.length; ++i) {

            if (String(analyses[i].band) === bandName)
                result.push(analyses[i])
        }

        result.sort(function(a, b) {
            return Number(a.channel) - Number(b.channel)
        })

        return result
    }


    function channelCongestionColor(score) {

        var value = Number(score)

        if (value >= 80)
            return "#ff3b30"

        if (value >= 60)
            return "#ff6b68"

        if (value >= 30)
            return "#ff8a84"

        return redBright
    }


    function channelQualityColor(quality) {

        var q = String(quality)

        if (q === "Very High" || q === "High")
            return red

        if (q === "Moderate")
            return "#ff8a84"

        return redBright
    }


    function channelRecommendation(bandName) {

        if (bandName === "2.4 GHz")
            return Number(wifiController.recommended24GHzChannel)

        if (bandName === "5 GHz")
            return Number(wifiController.recommended5GHzChannel)

        if (bandName === "6 GHz")
            return Number(wifiController.recommended6GHzChannel)

        return 0
    }


    function channelRecommendationDetails(bandName) {

        var details =
            wifiController.channelRecommendations

        if (!details)
            return null

        for (var i = 0; i < details.length; ++i) {

            if (String(details[i].band) === bandName)
                return details[i]
        }

        return null
    }


    function hasDetectedBand(bandName) {

        return channelAnalysesForBand(bandName).length > 0
    }


    function strongestRssiForBand(bandName) {

        var analyses =
            channelAnalysesForBand(bandName)

        if (analyses.length === 0)
            return 0

        var strongest = -1000

        for (var i = 0; i < analyses.length; ++i) {

            strongest =
                Math.max(
                    strongest,
                    Number(analyses[i].strongestRssi)
                )
        }

        return strongest
    }


    // =========================================================
    // MAIN SCROLL VIEW
    // =========================================================

    ScrollView {

        id:
            scrollView

        anchors.fill:
            parent

        clip:
            true

        ScrollBar.vertical.policy:
            ScrollBar.AsNeeded

        ScrollBar.horizontal.policy:
            ScrollBar.AlwaysOff


        Column {

            id:
                dashboard

            width:
                Math.max(
                    scrollView.availableWidth - 32,
                    918
                )

            anchors.horizontalCenter:
                parent.horizontalCenter

            topPadding:
                24

            bottomPadding:
                40

            spacing:
                16


            // =====================================================
            // HEADER
            // =====================================================

            Row {

                width:
                    parent.width

                height:
                    62

                spacing:
                    16


                Column {

                    width:
                        parent.width -
                        statusCard.width -
                        16

                    spacing:
                        4


                    Text {

                        text:
                            "WiFi Monitor"

                        color:
                            textPrimary

                        font.pixelSize:
                            30

                        font.bold:
                            true
                    }


                    Text {

                        text:
                            wifiController.connected
                            ?
                            wifiController.ssid
                            :
                            "No active Wi-Fi connection"

                        color:
                            textSecondary

                        font.pixelSize:
                            14
                    }
                }


                Rectangle {

                    id:
                        statusCard

                    width:
                        170

                    height:
                        50

                    radius:
                        13

                    color:
                        wifiController.connected
                        ?
                        redDark
                        :
                        "#151619"

                    border.width:
                        1

                    border.color:
                        wifiController.connected
                        ?
                        "#8c2529"
                        :
                        border


                    Row {

                        anchors.centerIn:
                            parent

                        spacing:
                            9


                        Rectangle {

                            width:
                                9

                            height:
                                9

                            radius:
                                5

                            color:
                                wifiController.connected
                                ?
                                red
                                :
                                "#5c6068"
                        }


                        Text {

                            text:
                                wifiController.connected
                                ?
                                "CONNECTED"
                                :
                                "DISCONNECTED"

                            color:
                                wifiController.connected
                                ?
                                redBright
                                :
                                textSecondary

                            font.pixelSize:
                                12

                            font.bold:
                                true
                        }
                    }
                }
            }


            // =====================================================
            // TOP METRICS
            // =====================================================

            Row {

                width:
                    parent.width

                height:
                    170

                spacing:
                    14


                Rectangle {

                    width:
                        (parent.width - 28) / 3

                    height:
                        parent.height

                    radius:
                        17

                    color:
                        card

                    border.width:
                        1

                    border.color:
                        border


                    Column {

                        anchors.fill:
                            parent

                        anchors.margins:
                            20

                        spacing:
                            7


                        Text {

                            text:
                                "SIGNAL"

                            color:
                                textSecondary

                            font.pixelSize:
                                11

                            font.bold:
                                true

                            font.letterSpacing:
                                1.5
                        }


                        Text {

                            text:
                                wifiController.connected
                                ?
                                wifiController.signalStrength +
                                " dBm"
                                :
                                "—"

                            color:
                                textPrimary

                            font.pixelSize:
                                32

                            font.bold:
                                true
                        }


                        Text {

                            text:
                                wifiController.connected
                                ?
                                wifiController.signalQuality
                                :
                                "—"

                            color:
                                wifiController.connected
                                ?
                                redBright
                                :
                                textMuted

                            font.pixelSize:
                                12

                            font.bold:
                                true
                        }


                        Rectangle {

                            width:
                                parent.width

                            height:
                                5

                            radius:
                                3

                            color:
                                "#24272d"


                            Rectangle {

                                width:
                                    signalPercentage(
                                        wifiController.signalStrength
                                    ) *
                                    parent.width /
                                    100

                                height:
                                    parent.height

                                radius:
                                    3

                                color:
                                    red
                            }
                        }
                    }
                }


                Rectangle {

                    width:
                        (parent.width - 28) / 3

                    height:
                        parent.height

                    radius:
                        17

                    color:
                        card

                    border.width:
                        1

                    border.color:
                        border


                    Column {

                        anchors.fill:
                            parent

                        anchors.margins:
                            20

                        spacing:
                            7


                        Text {

                            text:
                                "SIGNAL-TO-NOISE"

                            color:
                                textSecondary

                            font.pixelSize:
                                11

                            font.bold:
                                true

                            font.letterSpacing:
                                1.5
                        }


                        Text {

                            text:
                                wifiController.connected
                                ?
                                wifiController.snr +
                                " dB"
                                :
                                "—"

                            color:
                                textPrimary

                            font.pixelSize:
                                32

                            font.bold:
                                true
                        }


                        Text {

                            text:
                                wifiController.connected
                                ?
                                wifiController.snrQuality
                                :
                                "—"

                            color:
                                wifiController.connected
                                ?
                                redBright
                                :
                                textMuted

                            font.pixelSize:
                                12

                            font.bold:
                                true
                        }


                        Rectangle {

                            width:
                                parent.width

                            height:
                                5

                            radius:
                                3

                            color:
                                "#24272d"


                            Rectangle {

                                width:
                                    snrPercentage(
                                        wifiController.snr
                                    ) *
                                    parent.width /
                                    100

                                height:
                                    parent.height

                                radius:
                                    3

                                color:
                                    red
                            }
                        }
                    }
                }


                Rectangle {

                    width:
                        (parent.width - 28) / 3

                    height:
                        parent.height

                    radius:
                        17

                    color:
                        card

                    border.width:
                        1

                    border.color:
                        border


                    Column {

                        anchors.fill:
                            parent

                        anchors.margins:
                            20

                        spacing:
                            7


                        Text {

                            text:
                                "TRANSMIT RATE"

                            color:
                                textSecondary

                            font.pixelSize:
                                11

                            font.bold:
                                true

                            font.letterSpacing:
                                1.5
                        }


                        Text {

                            text:
                                wifiController.connected
                                ?
                                Number(
                                    wifiController.transmitRate
                                ).toFixed(1) +
                                " Mbps"
                                :
                                "—"

                            color:
                                textPrimary

                            font.pixelSize:
                                32

                            font.bold:
                                true
                        }


                        Text {

                            text:
                                "Current PHY rate"

                            color:
                                textSecondary

                            font.pixelSize:
                                12
                        }


                        Text {

                            text:
                                wifiController.connected
                                ?
                                wifiController.phyMode
                                :
                                "—"

                            color:
                                "#c5c7cc"

                            font.pixelSize:
                                12
                        }
                    }
                }
            }


            // =====================================================
            // NETWORK
            // =====================================================

            Rectangle {

                width:
                    parent.width

                height:
                    132

                radius:
                    17

                color:
                    card

                border.width:
                    1

                border.color:
                    border


                Column {

                    anchors.fill:
                        parent

                    anchors.margins:
                        18

                    spacing:
                        12


                    Text {

                        text:
                            "NETWORK"

                        color:
                            textSecondary

                        font.pixelSize:
                            11

                        font.bold:
                            true

                        font.letterSpacing:
                            1.5
                    }


                    Row {

                        width:
                            parent.width

                        spacing:
                            40


                        Column {

                            width:
                                parent.width / 2 - 20

                            spacing:
                                4


                            Text {

                                text:
                                    "SSID"

                                color:
                                    "#656971"

                                font.pixelSize:
                                    11
                            }


                            Text {

                                text:
                                    wifiController.connected
                                    ?
                                    wifiController.ssid
                                    :
                                    "—"

                                color:
                                    textPrimary

                                font.pixelSize:
                                    17

                                font.bold:
                                    true

                                elide:
                                    Text.ElideRight

                                width:
                                    parent.width
                            }
                        }


                        Column {

                            width:
                                parent.width / 2 - 20

                            spacing:
                                4


                            Text {

                                text:
                                    "BSSID"

                                color:
                                    "#656971"

                                font.pixelSize:
                                    11
                            }


                            Text {

                                text:
                                    wifiController.connected
                                    ?
                                    wifiController.bssid
                                    :
                                    "—"

                                color:
                                    textPrimary

                                font.pixelSize:
                                    17

                                font.bold:
                                    true
                            }
                        }
                    }
                }
            }


            // =====================================================
            // RADIO
            // =====================================================

            Rectangle {

                width:
                    parent.width

                height:
                    132

                radius:
                    17

                color:
                    card

                border.width:
                    1

                border.color:
                    border


                Column {

                    anchors.fill:
                        parent

                    anchors.margins:
                        18

                    spacing:
                        12


                    Text {

                        text:
                            "RADIO"

                        color:
                            textSecondary

                        font.pixelSize:
                            11

                        font.bold:
                            true

                        font.letterSpacing:
                            1.5
                    }


                    Row {

                        width:
                            parent.width

                        spacing:
                            9


                        Repeater {

                            model: [

                                {
                                    label: "CHANNEL",
                                    value:
                                        wifiController.connected
                                        ?
                                        String(
                                            wifiController.channel
                                        )
                                        :
                                        "—"
                                },

                                {
                                    label: "BAND",
                                    value:
                                        wifiController.connected
                                        ?
                                        wifiController.band
                                        :
                                        "—"
                                },

                                {
                                    label: "PHY",
                                    value:
                                        wifiController.connected
                                        ?
                                        wifiController.phyMode
                                        :
                                        "—"
                                },

                                {
                                    label: "WIDTH",
                                    value:
                                        wifiController.connected
                                        ?
                                        wifiController.channelWidth
                                        :
                                        "—"
                                },

                                {
                                    label: "NOISE",
                                    value:
                                        wifiController.connected
                                        ?
                                        wifiController.noise +
                                        " dBm"
                                        :
                                        "—"
                                }
                            ]


                            delegate:
                                Rectangle {

                                width:
                                    (parent.width - 36) / 5

                                height:
                                    63

                                radius:
                                    11

                                color:
                                    cardInner

                                border.width:
                                    1

                                border.color:
                                    border


                                Column {

                                    anchors.centerIn:
                                        parent

                                    spacing:
                                        5


                                    Text {

                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text:
                                            modelData.label

                                        color:
                                            "#656971"

                                        font.pixelSize:
                                            9

                                        font.bold:
                                            true

                                        font.letterSpacing:
                                            0.7
                                    }


                                    Text {

                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text:
                                            modelData.value

                                        color:
                                            "#e7e8eb"

                                        font.pixelSize:
                                            13

                                        font.bold:
                                            true
                                    }
                                }
                            }
                        }
                    }
                }
            }


            // =====================================================
            // SIGNAL HISTORY
            // =====================================================

            Rectangle {

                width:
                    parent.width

                height:
                    310

                radius:
                    17

                color:
                    card

                border.width:
                    1

                border.color:
                    border


                Column {

                    anchors.fill:
                        parent

                    anchors.margins:
                        18

                    spacing:
                        10


                    Row {

                        width:
                            parent.width

                        height:
                            20


                        Text {

                            text:
                                "SIGNAL HISTORY"

                            color:
                                textSecondary

                            font.pixelSize:
                                11

                            font.bold:
                                true

                            font.letterSpacing:
                                1.5
                        }


                        Item {

                            width:
                                parent.width -
                                currentRssi.width -
                                120

                            height:
                                1
                        }


                        Text {

                            id:
                                currentRssi

                            text:
                                wifiController.connected
                                ?
                                wifiController.signalStrength +
                                " dBm"
                                :
                                "—"

                            color:
                                textPrimary

                            font.pixelSize:
                                13

                            font.bold:
                                true

                            width:
                                80

                            horizontalAlignment:
                                Text.AlignRight
                        }
                    }


                    // =================================================
                    // MAIN RSSI GRAPH
                    //
                    // Y AXIS:
                    //   0
                    //  -20
                    //  -40
                    //  -60
                    //  -80
                    // -100
                    // =================================================

                    Rectangle {

                        width:
                            parent.width

                        height:
                            250

                        radius:
                            12

                        color:
                            cardInner

                        border.width:
                            1

                        border.color:
                            "#202329"


                        Canvas {

                            id:
                                mainRssiGraph

                            anchors.fill:
                                parent

                            anchors.margins:
                                12


                            property var values:
                                wifiController.rssiHistory


                            Connections {

                                target:
                                    wifiController

                                function onHistoryChanged() {

                                    mainRssiGraph.requestPaint()
                                }
                            }


                            onValuesChanged:
                                requestPaint()


                            onPaint: {

                                var ctx =
                                    getContext("2d")


                                ctx.clearRect(
                                    0,
                                    0,
                                    width,
                                    height
                                )


                                var axisWidth =
                                    38

                                var bottomHeight =
                                    20

                                var graphWidth =
                                    width -
                                    axisWidth

                                var graphHeight =
                                    height -
                                    bottomHeight


                                // -----------------------------------------
                                // GRID
                                // -----------------------------------------

                                var gridValues = [
                                    0,
                                    -20,
                                    -40,
                                    -60,
                                    -80,
                                    -100
                                ]


                                ctx.font =
                                    "10px sans-serif"

                                ctx.textAlign =
                                    "left"

                                ctx.textBaseline =
                                    "middle"


                                for (
                                    var g = 0;
                                    g < gridValues.length;
                                    ++g
                                ) {

                                    var value =
                                        gridValues[g]


                                    var normalized =
                                        (
                                            value + 100
                                        ) /
                                        100


                                    var y =
                                        graphHeight -
                                        normalized *
                                        graphHeight


                                    // grid line

                                    ctx.beginPath()

                                    ctx.moveTo(
                                        axisWidth,
                                        y
                                    )

                                    ctx.lineTo(
                                        width,
                                        y
                                    )

                                    ctx.strokeStyle =
                                        "#20242a"

                                    ctx.lineWidth =
                                        1

                                    ctx.stroke()


                                    // Y-axis label

                                    ctx.fillStyle =
                                        "#676c75"

                                    ctx.fillText(
                                        String(value),
                                        3,
                                        y
                                    )
                                }


                                if (
                                    !values ||
                                    values.length < 2
                                ) {
                                    return
                                }


                                // -----------------------------------------
                                // RSSI LINE
                                // -----------------------------------------

                                ctx.beginPath()


                                for (
                                    var i = 0;
                                    i < values.length;
                                    ++i
                                ) {

                                    var x =
                                        axisWidth +
                                        i *
                                        graphWidth /
                                        (
                                            values.length - 1
                                        )


                                    var rssi =
                                        Number(
                                            values[i]
                                        )


                                    var normalizedRssi =
                                        (
                                            rssi + 100
                                        ) /
                                        100


                                    var yRssi =
                                        graphHeight -
                                        normalizedRssi *
                                        graphHeight


                                    if (i === 0) {

                                        ctx.moveTo(
                                            x,
                                            yRssi
                                        )

                                    } else {

                                        ctx.lineTo(
                                            x,
                                            yRssi
                                        )
                                    }
                                }


                                ctx.strokeStyle =
                                    red

                                ctx.lineWidth =
                                    2

                                ctx.stroke()


                                // -----------------------------------------
                                // CURRENT POINT
                                // -----------------------------------------

                                var last =
                                    Number(
                                        values[
                                            values.length - 1
                                        ]
                                    )


                                var lastNormalized =
                                    (
                                        last + 100
                                    ) /
                                    100


                                var lastY =
                                    graphHeight -
                                    lastNormalized *
                                    graphHeight


                                ctx.beginPath()


                                ctx.arc(
                                    width,
                                    lastY,
                                    4,
                                    0,
                                    Math.PI * 2
                                )


                                ctx.fillStyle =
                                    redBright

                                ctx.fill()


                                // -----------------------------------------
                                // TIME AXIS
                                // -----------------------------------------

                                ctx.font =
                                    "10px sans-serif"

                                ctx.fillStyle =
                                    "#555a63"

                                ctx.textBaseline =
                                    "alphabetic"


                                ctx.fillText(
                                    "60s ago",
                                    axisWidth,
                                    height - 3
                                )


                                ctx.textAlign =
                                    "center"

                                ctx.fillText(
                                    "30s",
                                    axisWidth +
                                    graphWidth / 2,
                                    height - 3
                                )


                                ctx.textAlign =
                                    "right"

                                ctx.fillText(
                                    "Now",
                                    width,
                                    height - 3
                                )
                            }
                        }
                    }
                }
            }


            // =====================================================
            // NEARBY NETWORKS
            // =====================================================

            Rectangle {

                width:
                    parent.width

                height:
                    Math.max(
                        230,
                        126 +
                        (
                            wifiController.nearbyNetworks.length *
                            50
                        )
                    )

                radius:
                    17

                color:
                    card

                border.width:
                    1

                border.color:
                    border


                Column {

                    anchors.fill:
                        parent

                    anchors.margins:
                        18

                    spacing:
                        10


                    // =================================================
                    // HEADER
                    // =================================================

                    Row {

                        width:
                            parent.width

                        height:
                            48


                        Column {

                            width:
                                parent.width -
                                scanButton.width -
                                20

                            spacing:
                                3


                            Row {

                                spacing:
                                    8

                                height:
                                    18


                                Text {

                                    text:
                                        "NEARBY NETWORKS"

                                    color:
                                        textSecondary

                                    font.pixelSize:
                                        11

                                    font.bold:
                                        true

                                    font.letterSpacing:
                                        1.5
                                }


                                Rectangle {

                                    width:
                                        48

                                    height:
                                        18

                                    radius:
                                        9

                                    color:
                                        wifiController.nearbyMonitoring
                                        ?
                                        redDark
                                        :
                                        "#151619"

                                    border.width:
                                        1

                                    border.color:
                                        wifiController.nearbyMonitoring
                                        ?
                                        "#6e2024"
                                        :
                                        border


                                    Row {

                                        anchors.centerIn:
                                            parent

                                        spacing:
                                            5


                                        Rectangle {

                                            id:
                                                liveDot

                                            width:
                                                6

                                            height:
                                                6

                                            radius:
                                                3

                                            color:
                                                wifiController.nearbyMonitoring
                                                ?
                                                redBright
                                                :
                                                textMuted
                                        }


                                        Text {

                                            text:
                                                wifiController.nearbyMonitoring
                                                ?
                                                "LIVE"
                                                :
                                                "IDLE"

                                            color:
                                                wifiController.nearbyMonitoring
                                                ?
                                                redBright
                                                :
                                                textMuted

                                            font.pixelSize:
                                                8

                                            font.bold:
                                                true
                                        }
                                    }
                                }
                            }


                            Text {

                                text:
                                    wifiController.nearbyNetworks.length +
                                    (
                                        wifiController.nearbyNetworks.length === 1
                                        ?
                                        " network detected"
                                        :
                                        " networks detected"
                                    ) +
                                    "  •  Last scan " +
                                    lastScanTime

                                color:
                                    textMuted

                                font.pixelSize:
                                    10
                            }
                        }


                        Rectangle {

                            id:
                                scanButton

                            width:
                                138

                            height:
                                38

                            radius:
                                10

                            color:
                                wifiController.nearbyMonitoring
                                ?
                                "#241012"
                                :
                                "#1b0c0e"

                            border.width:
                                1

                            border.color:
                                red


                            Row {

                                anchors.centerIn:
                                    parent

                                spacing:
                                    7


                                Text {

                                    id:
                                        scanIcon

                                    text:
                                        "↻"

                                    color:
                                        redBright

                                    font.pixelSize:
                                        18

                                    font.bold:
                                        true
                                }


                                Text {

                                    text:
                                        wifiController.nearbyMonitoring
                                        ?
                                        "LIVE SCAN"
                                        :
                                        "SCAN NETWORKS"

                                    color:
                                        redBright

                                    font.pixelSize:
                                        10

                                    font.bold:
                                        true

                                    font.letterSpacing:
                                        0.5
                                }
                            }


                            MouseArea {

                                anchors.fill:
                                    parent

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked: {

                                    wifiController.scanNetworks()
                                }


                                onPressed: {

                                    scanButton.opacity =
                                        0.75
                                }


                                onReleased: {

                                    scanButton.opacity =
                                        1.0
                                }
                            }
                        }
                    }


                    // =================================================
                    // TABLE HEADER
                    // =================================================

                    Rectangle {

                        width:
                            parent.width

                        height:
                            28

                        radius:
                            7

                        color:
                            "#090b0e"


                        Row {

                            anchors.fill:
                                parent

                            anchors.leftMargin:
                                12

                            anchors.rightMargin:
                                12


                            Text {
                                width: parent.width * 0.27
                                text: "NETWORK"
                                color: "#656971"
                                font.pixelSize: 9
                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.18
                                text: "BSSID"
                                color: "#656971"
                                font.pixelSize: 9
                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.10
                                text: "RSSI"
                                color: "#656971"
                                font.pixelSize: 9
                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.10
                                text: "SNR"
                                color: "#656971"
                                font.pixelSize: 9
                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.10
                                text: "CHANNEL"
                                color: "#656971"
                                font.pixelSize: 9
                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.10
                                text: "BAND"
                                color: "#656971"
                                font.pixelSize: 9
                                font.bold: true
                            }

                            Text {
                                width: parent.width * 0.15
                                text: "QUALITY"
                                color: "#656971"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }


                    // =================================================
                    // EMPTY STATE
                    // =================================================

                    Rectangle {

                        visible:
                            wifiController.nearbyNetworks.length === 0

                        width:
                            parent.width

                        height:
                            70

                        radius:
                            9

                        color:
                            cardInner

                        border.width:
                            1

                        border.color:
                            "#202329"


                        Column {

                            anchors.centerIn:
                                parent

                            spacing:
                                4


                            Text {

                                anchors.horizontalCenter:
                                    parent.horizontalCenter

                                text:
                                    "No nearby networks detected"

                                color:
                                    "#777b84"

                                font.pixelSize:
                                    12
                            }


                            Text {

                                anchors.horizontalCenter:
                                    parent.horizontalCenter

                                text:
                                    "Press  ↻  SCAN NETWORKS  to scan again"

                                color:
                                    textMuted

                                font.pixelSize:
                                    10
                            }
                        }
                    }


                    // =================================================
                    // NETWORK ROWS
                    // =================================================

                    Repeater {

                        model:
                            wifiController.nearbyNetworks


                        delegate:
                            Rectangle {

                            id:
                                delegateItem

                            width:
                                parent.width

                            height:
                                42

                            radius:
                                9


                            property bool isCurrent:
                                String(modelData.bssid) ===
                                String(wifiController.bssid)


                            property bool isSelected:
                                String(modelData.bssid) ===
                                String(wifiController.selectedNetworkBssid)


                            property int currentRssi:
                                Number(
                                    modelData.signalStrength
                                )


                            property int currentSnr:
                                Number(
                                    modelData.snr
                                )


                            property int rssiChange:
                                rssiDelta(
                                    modelData.bssid
                                )


                            property int snrChange:
                                snrDelta(
                                    modelData.bssid
                                )


                            color:
                                isSelected
                                ?
                                selectedRow
                                :
                                cardInner


                            border.width:
                                1

                            border.color:
                                isSelected
                                ?
                                red
                                :
                                "#202329"


                            Rectangle {

                                id:
                                    updateFlash

                                anchors.fill:
                                    parent

                                radius:
                                    parent.radius

                                color:
                                    red

                                opacity:
                                    0

                                z:
                                    1


                                SequentialAnimation {

                                    id:
                                        flashAnimation

                                    running:
                                        false


                                    PropertyAnimation {

                                        target:
                                            updateFlash

                                        property:
                                            "opacity"

                                        from:
                                            0.10

                                        to:
                                            0

                                        duration:
                                            450
                                    }
                                }


                                Connections {

                                    target:
                                        root


                                    function onScanUpdateNumberChanged() {

                                        if (
                                            delegateItem.rssiChange !== 0 ||
                                            delegateItem.snrChange !== 0
                                        ) {

                                            flashAnimation.restart()
                                        }
                                    }
                                }
                            }


                            Row {

                                anchors.fill:
                                    parent

                                anchors.leftMargin:
                                    12

                                anchors.rightMargin:
                                    12

                                z:
                                    2


                                Text {

                                    width:
                                        parent.width * 0.27

                                    text:
                                        String(
                                            modelData.ssid
                                        ) !== ""
                                        ?
                                        String(
                                            modelData.ssid
                                        )
                                        :
                                        "<Hidden Network>"

                                    color:
                                        isSelected
                                        ?
                                        redBright
                                        :
                                        textPrimary

                                    font.pixelSize:
                                        10

                                    font.bold:
                                        isSelected

                                    verticalAlignment:
                                        Text.AlignVCenter

                                    elide:
                                        Text.ElideRight
                                }


                                Text {

                                    width:
                                        parent.width * 0.18

                                    text:
                                        String(
                                            modelData.bssid
                                        )

                                    color:
                                        textSecondary

                                    font.pixelSize:
                                        9

                                    verticalAlignment:
                                        Text.AlignVCenter
                                }


                                Row {

                                    width:
                                        parent.width * 0.10

                                    spacing:
                                        4


                                    Text {

                                        text:
                                            String(
                                                delegateItem.currentRssi
                                            ) +
                                            " dBm"

                                        color:
                                            qualityColor(
                                                modelData.signalQuality
                                            )

                                        font.pixelSize:
                                            10

                                        font.bold:
                                            true
                                    }


                                    Text {

                                        visible:
                                            delegateItem.rssiChange !== 0

                                        text:
                                            deltaArrow(
                                                delegateItem.rssiChange
                                            ) +
                                            formatDelta(
                                                delegateItem.rssiChange
                                            )

                                        color:
                                            deltaColor(
                                                delegateItem.rssiChange
                                            )

                                        font.pixelSize:
                                            8

                                        font.bold:
                                            true
                                    }
                                }


                                Row {

                                    width:
                                        parent.width * 0.10

                                    spacing:
                                        4


                                    Text {

                                        text:
                                            String(
                                                delegateItem.currentSnr
                                            ) +
                                            " dB"

                                        color:
                                            textPrimary

                                        font.pixelSize:
                                            10
                                    }


                                    Text {

                                        visible:
                                            delegateItem.snrChange !== 0

                                        text:
                                            deltaArrow(
                                                delegateItem.snrChange
                                            ) +
                                            formatDelta(
                                                delegateItem.snrChange
                                            )

                                        color:
                                            deltaColor(
                                                delegateItem.snrChange
                                            )

                                        font.pixelSize:
                                            8

                                        font.bold:
                                            true
                                    }
                                }


                                Text {

                                    width:
                                        parent.width * 0.10

                                    text:
                                        String(
                                            modelData.channel
                                        )

                                    color:
                                        textPrimary

                                    font.pixelSize:
                                        10
                                }


                                Text {

                                    width:
                                        parent.width * 0.10

                                    text:
                                        String(
                                            modelData.band
                                        )

                                    color:
                                        textPrimary

                                    font.pixelSize:
                                        10
                                }


                                Text {

                                    width:
                                        parent.width * 0.15

                                    text:
                                        String(
                                            modelData.signalQuality
                                        ) !== ""
                                        ?
                                        String(
                                            modelData.signalQuality
                                        )
                                        :
                                        "Unknown"

                                    color:
                                        qualityColor(
                                            modelData.signalQuality
                                        )

                                    font.pixelSize:
                                        10

                                    font.bold:
                                        true
                                }
                            }


                            MouseArea {

                                anchors.fill:
                                    parent

                                z:
                                    5

                                cursorShape:
                                    Qt.PointingHandCursor

                                onClicked: {

                                    root.selectNetwork(
                                        modelData
                                    )
                                }
                            }
                        }
                    }
                }
            }


            // =====================================================
            // SELECTED NETWORK
            // =====================================================

            Rectangle {

                visible:
                    root.selectedNetworkData !== null

                width:
                    parent.width

                height:
                    405

                radius:
                    17

                color:
                    card

                border.width:
                    1

                border.color:
                    red


                Column {

                    anchors.fill:
                        parent

                    anchors.margins:
                        16

                    spacing:
                        10


                    Row {

                        width:
                            parent.width

                        height:
                            42


                        Column {

                            width:
                                parent.width -
                                liveSelectedBadge.width -
                                16

                            spacing:
                                2


                            Text {

                                text:
                                    "SELECTED NETWORK"

                                color:
                                    textSecondary

                                font.pixelSize:
                                    11

                                font.bold:
                                    true

                                font.letterSpacing:
                                    1.5
                            }


                            Text {

                                text:
                                    root.selectedNetworkData
                                    ?
                                    (
                                        String(
                                            root.selectedNetworkData.ssid
                                        ) !== ""
                                        ?
                                        String(
                                            root.selectedNetworkData.ssid
                                        )
                                        :
                                        "<Hidden Network>"
                                    )
                                    :
                                    "—"

                                color:
                                    textPrimary

                                font.pixelSize:
                                    17

                                font.bold:
                                    true
                            }
                        }


                        Rectangle {

                            id:
                                liveSelectedBadge

                            width:
                                52

                            height:
                                20

                            radius:
                                10

                            color:
                                wifiController.nearbyMonitoring
                                ?
                                redDark
                                :
                                "#151619"

                            border.width:
                                1

                            border.color:
                                wifiController.nearbyMonitoring
                                ?
                                "#6e2024"
                                :
                                border


                            Row {

                                anchors.centerIn:
                                    parent

                                spacing:
                                    5


                                Rectangle {

                                    width:
                                        6

                                    height:
                                        6

                                    radius:
                                        3

                                    color:
                                        wifiController.nearbyMonitoring
                                        ?
                                        redBright
                                        :
                                        textMuted
                                }


                                Text {

                                    text:
                                        wifiController.nearbyMonitoring
                                        ?
                                        "LIVE"
                                        :
                                        "IDLE"

                                    color:
                                        wifiController.nearbyMonitoring
                                        ?
                                        redBright
                                        :
                                        textMuted

                                    font.pixelSize:
                                        8

                                    font.bold:
                                        true
                                }
                            }
                        }
                    }


                    // =================================================
                    // SELECTED METRICS
                    // =================================================

                    Row {

                        width:
                            parent.width

                        height:
                            55

                        spacing:
                            9


                        Repeater {

                            model: [

                                {
                                    label: "RSSI",

                                    value:
                                        root.selectedNetworkData
                                        ?
                                        Number(
                                            root.selectedNetworkData
                                            .signalStrength
                                        ) +
                                        " dBm"
                                        :
                                        "—"
                                },

                                {
                                    label: "SNR",

                                    value:
                                        root.selectedNetworkData
                                        ?
                                        Number(
                                            root.selectedNetworkData
                                            .snr
                                        ) +
                                        " dB"
                                        :
                                        "—"
                                },

                                {
                                    label: "CHANNEL",

                                    value:
                                        root.selectedNetworkData
                                        ?
                                        String(
                                            root.selectedNetworkData
                                            .channel
                                        )
                                        :
                                        "—"
                                },

                                {
                                    label: "BAND",

                                    value:
                                        root.selectedNetworkData
                                        ?
                                        String(
                                            root.selectedNetworkData
                                            .band
                                        )
                                        :
                                        "—"
                                }
                            ]


                            delegate:
                                Rectangle {

                                width:
                                    (parent.width - 27) / 4

                                height:
                                    55

                                radius:
                                    10

                                color:
                                    cardInner

                                border.width:
                                    1

                                border.color:
                                    border


                                Column {

                                    anchors.centerIn:
                                        parent

                                    spacing:
                                        4


                                    Text {

                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text:
                                            modelData.label

                                        color:
                                            "#656971"

                                        font.pixelSize:
                                            8

                                        font.bold:
                                            true
                                    }


                                    Text {

                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text:
                                            modelData.value

                                        color:
                                            textPrimary

                                        font.pixelSize:
                                            13

                                        font.bold:
                                            true
                                    }
                                }
                            }
                        }
                    }


                    // =================================================
                    // BSSID / QUALITY
                    // =================================================

                    Row {

                        width:
                            parent.width

                        height:
                            20


                        Text {

                            width:
                                parent.width * 0.55

                            text:
                                root.selectedNetworkData
                                ?
                                "BSSID  " +
                                String(
                                    root.selectedNetworkData.bssid
                                )
                                :
                                ""

                            color:
                                textSecondary

                            font.pixelSize:
                                9
                        }


                        Text {

                            width:
                                parent.width * 0.22

                            text:
                                root.selectedNetworkData
                                ?
                                String(
                                    root.selectedNetworkData
                                    .signalQuality
                                )
                                :
                                ""

                            color:
                                root.selectedNetworkData
                                ?
                                qualityColor(
                                    root.selectedNetworkData
                                    .signalQuality
                                )
                                :
                                textMuted

                            font.pixelSize:
                                9

                            font.bold:
                                true
                        }


                        Text {

                            width:
                                parent.width * 0.23

                            text:
                                root.selectedNetworkData
                                ?
                                String(
                                    root.selectedNetworkData
                                    .snrQuality
                                )
                                :
                                ""

                            color:
                                root.selectedNetworkData
                                ?
                                qualityColor(
                                    root.selectedNetworkData
                                    .snrQuality
                                )
                                :
                                textMuted

                            font.pixelSize:
                                9

                            font.bold:
                                true

                            horizontalAlignment:
                                Text.AlignRight
                        }
                    }


                    // =================================================
                    // SELECTED GRAPHS
                    // =================================================

                    Row {

                        width:
                            parent.width

                        height:
                            195

                        spacing:
                            10


                        // =============================================
                        // SELECTED RSSI
                        // =============================================

                        Rectangle {

                            width:
                                (parent.width - 10) / 2

                            height:
                                parent.height

                            radius:
                                11

                            color:
                                cardInner

                            border.width:
                                1

                            border.color:
                                "#202329"


                            Column {

                                anchors.fill:
                                    parent

                                anchors.margins:
                                    10

                                spacing:
                                    5


                                Text {

                                    text:
                                        "RSSI HISTORY"

                                    color:
                                        textSecondary

                                    font.pixelSize:
                                        9

                                    font.bold:
                                        true

                                    font.letterSpacing:
                                        1.1
                                }


                                Canvas {

                                    id:
                                        selectedRssiGraph

                                    width:
                                        parent.width

                                    height:
                                        parent.height - 20


                                    property var values:
                                        wifiController.selectedNetworkRssiHistory


                                    onValuesChanged:
                                        requestPaint()


                                    onPaint: {

                                        var ctx =
                                            getContext("2d")


                                        ctx.clearRect(
                                            0,
                                            0,
                                            width,
                                            height
                                        )


                                        var axisWidth =
                                            34

                                        var graphWidth =
                                            width -
                                            axisWidth


                                        var graphHeight =
                                            height -
                                            8


                                        var gridValues = [
                                            -20,
                                            -40,
                                            -60,
                                            -80,
                                            -100
                                        ]


                                        // ---------------------------------
                                        // GRID + Y LABELS
                                        // ---------------------------------

                                        ctx.font =
                                            "9px sans-serif"

                                        ctx.textAlign =
                                            "left"

                                        ctx.textBaseline =
                                            "middle"


                                        for (
                                            var g = 0;
                                            g < gridValues.length;
                                            ++g
                                        ) {

                                            var value =
                                                gridValues[g]


                                            var normalized =
                                                (
                                                    value + 100
                                                ) /
                                                80


                                            normalized =
                                                Math.max(
                                                    0,
                                                    Math.min(
                                                        1,
                                                        normalized
                                                    )
                                                )


                                            var y =
                                                graphHeight -
                                                normalized *
                                                graphHeight


                                            ctx.beginPath()

                                            ctx.moveTo(
                                                axisWidth,
                                                y
                                            )

                                            ctx.lineTo(
                                                width,
                                                y
                                            )

                                            ctx.strokeStyle =
                                                "#20242a"

                                            ctx.lineWidth =
                                                1

                                            ctx.stroke()


                                            ctx.fillStyle =
                                                "#676c75"

                                            ctx.fillText(
                                                String(value),
                                                2,
                                                y
                                            )
                                        }


                                        if (
                                            !values ||
                                            values.length < 2
                                        ) {
                                            return
                                        }


                                        // ---------------------------------
                                        // RSSI LINE
                                        // ---------------------------------

                                        ctx.beginPath()


                                        for (
                                            var i = 0;
                                            i < values.length;
                                            ++i
                                        ) {

                                            var x =
                                                axisWidth +
                                                i *
                                                graphWidth /
                                                (
                                                    values.length - 1
                                                )


                                            var rssi =
                                                Number(
                                                    values[i]
                                                )


                                            var normalizedRssi =
                                                (
                                                    rssi + 100
                                                ) /
                                                80


                                            normalizedRssi =
                                                Math.max(
                                                    0,
                                                    Math.min(
                                                        1,
                                                        normalizedRssi
                                                    )
                                                )


                                            var yRssi =
                                                graphHeight -
                                                normalizedRssi *
                                                graphHeight


                                            if (
                                                i === 0
                                            ) {

                                                ctx.moveTo(
                                                    x,
                                                    yRssi
                                                )

                                            } else {

                                                ctx.lineTo(
                                                    x,
                                                    yRssi
                                                )
                                            }
                                        }


                                        ctx.strokeStyle =
                                            red

                                        ctx.lineWidth =
                                            2

                                        ctx.stroke()


                                        var last =
                                            Number(
                                                values[
                                                    values.length - 1
                                                ]
                                            )


                                        var lastNormalized =
                                            (
                                                last + 100
                                            ) /
                                            80


                                        lastNormalized =
                                            Math.max(
                                                0,
                                                Math.min(
                                                    1,
                                                    lastNormalized
                                                )
                                            )


                                        var lastY =
                                            graphHeight -
                                            lastNormalized *
                                            graphHeight


                                        ctx.beginPath()


                                        ctx.arc(
                                            width,
                                            lastY,
                                            4,
                                            0,
                                            Math.PI * 2
                                        )


                                        ctx.fillStyle =
                                            redBright

                                        ctx.fill()
                                    }
                                }
                            }
                        }


                        // =============================================
                        // SELECTED SNR
                        // =============================================

                        Rectangle {

                            width:
                                (parent.width - 10) / 2

                            height:
                                parent.height

                            radius:
                                11

                            color:
                                cardInner

                            border.width:
                                1

                            border.color:
                                "#202329"


                            Column {

                                anchors.fill:
                                    parent

                                anchors.margins:
                                    10

                                spacing:
                                    5


                                Text {

                                    text:
                                        "SNR HISTORY"

                                    color:
                                        textSecondary

                                    font.pixelSize:
                                        9

                                    font.bold:
                                        true

                                    font.letterSpacing:
                                        1.1
                                }


                                Canvas {

                                    id:
                                        selectedSnrGraph

                                    width:
                                        parent.width

                                    height:
                                        parent.height - 20


                                    property var values:
                                        wifiController.selectedNetworkSnrHistory


                                    onValuesChanged:
                                        requestPaint()


                                    onPaint: {

                                        var ctx =
                                            getContext("2d")


                                        ctx.clearRect(
                                            0,
                                            0,
                                            width,
                                            height
                                        )


                                        var axisWidth =
                                            32

                                        var graphWidth =
                                            width -
                                            axisWidth

                                        var graphHeight =
                                            height -
                                            8


                                        var gridValues = [
                                            70,
                                            60,
                                            50,
                                            40,
                                            30,
                                            20,
                                            10,
                                            0
                                        ]


                                        // ---------------------------------
                                        // GRID + Y LABELS
                                        // ---------------------------------

                                        ctx.font =
                                            "9px sans-serif"

                                        ctx.textAlign =
                                            "left"

                                        ctx.textBaseline =
                                            "middle"


                                        for (
                                            var g = 0;
                                            g < gridValues.length;
                                            ++g
                                        ) {

                                            var value =
                                                gridValues[g]


                                            var normalized =
                                                value / 70


                                            var y =
                                                graphHeight -
                                                normalized *
                                                graphHeight


                                            ctx.beginPath()

                                            ctx.moveTo(
                                                axisWidth,
                                                y
                                            )

                                            ctx.lineTo(
                                                width,
                                                y
                                            )

                                            ctx.strokeStyle =
                                                "#20242a"

                                            ctx.lineWidth =
                                                1

                                            ctx.stroke()


                                            ctx.fillStyle =
                                                "#676c75"

                                            ctx.fillText(
                                                String(value),
                                                2,
                                                y
                                            )
                                        }


                                        if (
                                            !values ||
                                            values.length < 2
                                        ) {
                                            return
                                        }


                                        // ---------------------------------
                                        // SNR LINE
                                        // ---------------------------------

                                        ctx.beginPath()


                                        for (
                                            var i = 0;
                                            i < values.length;
                                            ++i
                                        ) {

                                            var x =
                                                axisWidth +
                                                i *
                                                graphWidth /
                                                (
                                                    values.length - 1
                                                )


                                            var snr =
                                                Number(
                                                    values[i]
                                                )


                                            var normalizedSnr =
                                                snr / 70


                                            normalizedSnr =
                                                Math.max(
                                                    0,
                                                    Math.min(
                                                        1,
                                                        normalizedSnr
                                                    )
                                                )


                                            var ySnr =
                                                graphHeight -
                                                normalizedSnr *
                                                graphHeight


                                            if (
                                                i === 0
                                            ) {

                                                ctx.moveTo(
                                                    x,
                                                    ySnr
                                                )

                                            } else {

                                                ctx.lineTo(
                                                    x,
                                                    ySnr
                                                )
                                            }
                                        }


                                        ctx.strokeStyle =
                                            red

                                        ctx.lineWidth =
                                            2

                                        ctx.stroke()


                                        var last =
                                            Number(
                                                values[
                                                    values.length - 1
                                                ]
                                            )


                                        var lastNormalized =
                                            last / 70


                                        lastNormalized =
                                            Math.max(
                                                0,
                                                Math.min(
                                                    1,
                                                    lastNormalized
                                                )
                                            )


                                        var lastY =
                                            graphHeight -
                                            lastNormalized *
                                            graphHeight


                                        ctx.beginPath()


                                        ctx.arc(
                                            width,
                                            lastY,
                                            4,
                                            0,
                                            Math.PI * 2
                                        )


                                        ctx.fillStyle =
                                            redBright

                                        ctx.fill()
                                    }
                                }
                            }
                        }
                    }
                }
            }


            // =====================================================
            // WI-FI ENVIRONMENT
            // =====================================================

            Rectangle {

                width:
                    parent.width

                height:
                    174

                radius:
                    17

                color:
                    card

                border.width:
                    1

                border.color:
                    border


                Column {

                    anchors.fill:
                        parent

                    anchors.margins:
                        18

                    spacing:
                        12


                    // =================================================
                    // HEADER
                    // =================================================

                    Row {

                        width:
                            parent.width

                        height:
                            24


                        Text {

                            text:
                                "WI-FI ENVIRONMENT"

                            color:
                                textSecondary

                            font.pixelSize:
                                11

                            font.bold:
                                true

                            font.letterSpacing:
                                1.5
                        }


                        Item {

                            width:
                                parent.width -
                                environmentCount.width -
                                20

                            height:
                                1
                        }


                        Text {

                            id:
                                environmentCount

                            text:
                                wifiController.nearbyNetworks.length +
                                (
                                    wifiController.nearbyNetworks.length === 1
                                    ?
                                    " NETWORK"
                                    :
                                    " NETWORKS"
                                )

                            color:
                                wifiController.nearbyNetworks.length > 0
                                ?
                                redBright
                                :
                                textMuted

                            font.pixelSize:
                                10

                            font.bold:
                                true
                        }
                    }


                    // =================================================
                    // BAND SUMMARY
                    // =================================================

                    Row {

                        width:
                            parent.width

                        height:
                            72

                        spacing:
                            10


                        Repeater {

                            model: [

                                {
                                    label:
                                        "NETWORKS",

                                    value:
                                        wifiController
                                        .nearbyNetworks
                                        .length
                                },

                                {
                                    label:
                                        "2.4 GHz",

                                    value:
                                        countBand(
                                            "2.4 GHz"
                                        )
                                },

                                {
                                    label:
                                        "5 GHz",

                                    value:
                                        countBand(
                                            "5 GHz"
                                        )
                                },

                                {
                                    label:
                                        "6 GHz",

                                    value:
                                        countBand(
                                            "6 GHz"
                                        )
                                }
                            ]


                            delegate:
                                Rectangle {

                                width:
                                    (parent.width - 30) / 4

                                height:
                                    72

                                radius:
                                    11

                                color:
                                    cardInner

                                border.width:
                                    1

                                border.color:
                                    border


                                Column {

                                    anchors.centerIn:
                                        parent

                                    spacing:
                                        5


                                    Text {

                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text:
                                            modelData.label

                                        color:
                                            "#656971"

                                        font.pixelSize:
                                            9

                                        font.bold:
                                            true
                                    }


                                    Text {

                                        anchors.horizontalCenter:
                                            parent.horizontalCenter

                                        text:
                                            String(
                                                modelData.value
                                            )

                                        color:
                                            textPrimary

                                        font.pixelSize:
                                            22

                                        font.bold:
                                            true
                                    }
                                }
                            }
                        }
                    }


                    // =================================================
                    // STATUS
                    // =================================================

                    Text {

                        width:
                            parent.width

                        text:
                            wifiController.nearbyNetworks.length > 0
                            ?
                            (
                                "Live environment • Last scan " +
                                lastScanTime
                            )
                            :
                            "No nearby networks detected • Press SCAN NETWORKS to begin"

                        color:
                            textMuted

                        font.pixelSize:
                            9

                        horizontalAlignment:
                            Text.AlignCenter
                    }
                }
            }


            // =====================================================
            // CHANNEL INTELLIGENCE
            // =====================================================

            Rectangle {

                width:
                    parent.width

                height:
                    700

                radius:
                    17

                color:
                    card

                border.width:
                    1

                border.color:
                    border


                Column {

                    anchors.fill:
                        parent

                    anchors.margins:
                        14

                    spacing:
                        12


                    // =================================================
                    // SECTION HEADER
                    // =================================================

                    Row {

                        width:
                            parent.width

                        height:
                            46


                        Column {

                            width:
                                parent.width -
                                channelIntelligenceStatus.width -
                                16

                            spacing:
                                2


                            Text {

                                text:
                                    "CHANNEL INTELLIGENCE"

                                color:
                                    textPrimary

                                font.pixelSize:
                                    18

                                font.bold:
                                    true

                                font.letterSpacing:
                                    1.2
                            }


                            Text {

                                text:
                                    "Observed channel usage, recommendations, and confidence"

                                color:
                                    textSecondary

                                font.pixelSize:
                                    13
                            }
                        }


                        Rectangle {

                            id:
                                channelIntelligenceStatus

                            width:
                                158

                            height:
                                38

                            radius:
                                10

                            color:
                                wifiController.nearbyNetworks.length > 0
                                ?
                                redDark
                                :
                                "#151619"

                            border.width:
                                1

                            border.color:
                                wifiController.nearbyNetworks.length > 0
                                ?
                                red
                                :
                                border


                            Text {

                                anchors.centerIn:
                                    parent

                                text:
                                    wifiController.nearbyNetworks.length > 0
                                    ?
                                    "✓  ANALYSIS READY"
                                    :
                                    "AWAITING SCAN"

                                color:
                                    wifiController.nearbyNetworks.length > 0
                                    ?
                                    redBright
                                    :
                                    textMuted

                                font.pixelSize:
                                    11

                                font.bold:
                                    true

                                font.letterSpacing:
                                    0.5
                            }
                        }
                    }


                    // =================================================
                    // BAND CARDS
                    // =================================================

                    Row {

                        width:
                            parent.width

                        height:
                            560

                        spacing:
                            10


                        Repeater {

                            model: [
                                "2.4 GHz",
                                "5 GHz",
                                "6 GHz"
                            ]


                            delegate:
                                Rectangle {

                                width:
                                    (parent.width - 20) / 3

                                height:
                                    560

                                radius:
                                    12

                                color:
                                    cardInner

                                border.width:
                                    1

                                border.color:
                                    border


                                property string bandName:
                                    modelData

                                property var analyses:
                                    channelAnalysesForBand(
                                        bandName
                                    )

                                property int recommendation:
                                    channelRecommendation(
                                        bandName
                                    )

                                property var recommendationDetails:
                                    channelRecommendationDetails(
                                        bandName
                                    )

                                property string recommendationConfidence:
                                    recommendationDetails
                                    ?
                                    String(
                                        recommendationDetails.confidenceLabel
                                    )
                                    :
                                    "No data"

                                property string recommendationReason:
                                    recommendationDetails
                                    ?
                                    String(
                                        recommendationDetails.reason
                                    )
                                    :
                                    "No scan data available."

                                property bool hasNetworks:
                                    analyses.length > 0


                                property int totalNetworks:
                                    analyses.reduce(
                                        function(total, item) {
                                            return total +
                                                   Number(
                                                       item.networkCount
                                                   )
                                        },
                                        0
                                    )

                                property int strongestRssi:
                                    analyses.length > 0
                                    ?
                                    analyses.reduce(
                                        function(strongest, item) {
                                            return Math.max(
                                                strongest,
                                                Number(
                                                    item.strongestRssi
                                                )
                                            )
                                        },
                                        -100
                                    )
                                    :
                                    0

                                property int averageRssi:
                                    analyses.length > 0
                                    ?
                                    Math.round(
                                        analyses.reduce(
                                            function(total, item) {
                                                return total +
                                                       (
                                                           Number(
                                                               item.averageRssi
                                                           ) *
                                                           Number(
                                                               item.networkCount
                                                           )
                                                       )
                                            },
                                            0
                                        ) /
                                        Math.max(
                                            1,
                                            totalNetworks
                                        )
                                    )
                                    :
                                    0

                                property int worstCongestion:
                                    analyses.length > 0
                                    ?
                                    analyses.reduce(
                                        function(worst, item) {
                                            return Math.max(
                                                worst,
                                                Number(
                                                    item.congestionScore
                                                )
                                            )
                                        },
                                        0
                                    )
                                    :
                                    0


                                Column {

                                    anchors.fill:
                                        parent

                                    anchors.margins:
                                        14

                                    spacing:
                                        10


                                    // ---------------------------------
                                    // BAND HEADER
                                    // ---------------------------------

                                    Item {

                                        width:
                                            parent.width

                                        height:
                                            38

                                        clip:
                                            true


                                        Text {

                                            id:
                                                bandTitle

                                            anchors.left:
                                                parent.left

                                            anchors.verticalCenter:
                                                parent.verticalCenter

                                            width:
                                                parent.width -
                                                bandApBadge.width -
                                                12

                                            text:
                                                bandName

                                            color:
                                                textPrimary

                                            font.pixelSize:
                                                20

                                            font.bold:
                                                true

                                            verticalAlignment:
                                                Text.AlignVCenter

                                            elide:
                                                Text.ElideRight
                                        }


                                        Rectangle {

                                            id:
                                                bandApBadge

                                            anchors.right:
                                                parent.right

                                            anchors.rightMargin:
                                                0

                                            anchors.verticalCenter:
                                                parent.verticalCenter

                                            width:
                                                96

                                            height:
                                                34

                                            radius:
                                                10

                                            color:
                                                "#111820"

                                            border.width:
                                                1

                                            border.color:
                                                borderStrong


                                            Row {

                                                anchors.centerIn:
                                                    parent

                                                spacing:
                                                    8


                                                Text {

                                                    text:
                                                        "⌁"

                                                    color:
                                                        textSecondary

                                                    font.pixelSize:
                                                        20

                                                    font.bold:
                                                        true

                                                    verticalAlignment:
                                                        Text.AlignVCenter
                                                }


                                                Text {

                                                    text:
                                                        hasNetworks
                                                        ?
                                                        totalNetworks +
                                                        (
                                                            totalNetworks === 1
                                                            ?
                                                            " AP"
                                                            :
                                                            " APs"
                                                        )
                                                        :
                                                        "0 APs"

                                                    color:
                                                        textPrimary

                                                    font.pixelSize:
                                                        12

                                                    font.bold:
                                                        true

                                                    verticalAlignment:
                                                        Text.AlignVCenter
                                                }
                                            }
                                        }
                                    }


                                    // ---------------------------------
                                    // RECOMMENDATION
                                    // ---------------------------------

                                    Rectangle {

                                        width:
                                            parent.width

                                        height:
                                            72

                                        radius:
                                            10

                                        color:
                                            hasNetworks &&
                                            recommendation > 0
                                            ?
                                            redDark
                                            :
                                            "#151619"

                                        border.width:
                                            1

                                        border.color:
                                            hasNetworks &&
                                            recommendation > 0
                                            ?
                                            red
                                            :
                                            borderStrong


                                        Row {

                                            anchors.fill:
                                                parent

                                            anchors.leftMargin:
                                                14

                                            anchors.rightMargin:
                                                14

                                            spacing:
                                                10


                                            Column {

                                                width:
                                                    parent.width -
                                                    recommendationChannel.width -
                                                    10

                                                anchors.verticalCenter:
                                                    parent.verticalCenter

                                                spacing:
                                                    3


                                                Text {

                                                    text:
                                                        hasNetworks &&
                                                        recommendation > 0
                                                        ?
                                                        "RECOMMENDED  •  " +
                                                        recommendationConfidence.toUpperCase()
                                                        :
                                                        "RECOMMENDATION"

                                                    color:
                                                        hasNetworks &&
                                                        recommendation > 0
                                                        ?
                                                        redBright
                                                        :
                                                        textSecondary

                                                    font.pixelSize:
                                                        11

                                                    font.bold:
                                                        true

                                                    font.letterSpacing:
                                                        0.5

                                                    elide:
                                                        Text.ElideRight

                                                    width:
                                                        parent.width
                                                }


                                                Text {

                                                    text:
                                                        hasNetworks &&
                                                        recommendation > 0
                                                        ?
                                                        "Channel " +
                                                        recommendation
                                                        :
                                                        "No scan data"

                                                    color:
                                                        textPrimary

                                                    font.pixelSize:
                                                        19

                                                    font.bold:
                                                        true
                                                }
                                            }


                                            Text {

                                                id:
                                                    recommendationChannel

                                                text:
                                                    hasNetworks &&
                                                    recommendation > 0
                                                    ?
                                                    "CH " +
                                                    recommendation
                                                    :
                                                    "—"

                                                color:
                                                    hasNetworks &&
                                                    recommendation > 0
                                                    ?
                                                    redBright
                                                    :
                                                    textSecondary

                                                font.pixelSize:
                                                    24

                                                font.bold:
                                                    true

                                                anchors.verticalCenter:
                                                    parent.verticalCenter
                                            }
                                        }
                                    }


                                    // ---------------------------------
                                    // RECOMMENDATION REASON
                                    // ---------------------------------
                                    // Removed completely from the UI.
                                    // No Rectangle and no Text are created here.

                                    // ---------------------------------
                                    // OBSERVED METRICS
                                    // ---------------------------------

                                    Row {

                                        width:
                                            parent.width

                                        height:
                                            70

                                        spacing:
                                            8


                                        Repeater {

                                            model: [

                                                {
                                                    label:
                                                        "STRONGEST",

                                                    value:
                                                        hasNetworks
                                                        ?
                                                        strongestRssi +
                                                        " dBm"
                                                        :
                                                        "—"
                                                },

                                                {
                                                    label:
                                                        "AVERAGE",

                                                    value:
                                                        hasNetworks
                                                        ?
                                                        averageRssi +
                                                        " dBm"
                                                        :
                                                        "—"
                                                },

                                                {
                                                    label:
                                                        "MAX CONGESTION SCORE",

                                                    value:
                                                        hasNetworks
                                                        ?
                                                        worstCongestion
                                                        :
                                                        "—"
                                                }
                                            ]


                                            delegate:
                                                Rectangle {

                                                width:
                                                    (
                                                        parent.width -
                                                        16
                                                    ) / 3

                                                height:
                                                    70

                                                radius:
                                                    9

                                                color:
                                                    "#0a0d11"

                                                border.width:
                                                    1

                                                border.color:
                                                    borderStrong


                                                Column {

                                                    anchors.centerIn:
                                                        parent

                                                    spacing:
                                                        5


                                                    Text {

                                                        width:
                                                            parent.width

                                                        text:
                                                            modelData.label

                                                        color:
                                                            textSecondary

                                                        font.pixelSize:
                                                            9

                                                        font.bold:
                                                            true

                                                        horizontalAlignment:
                                                            Text.AlignHCenter

                                                        wrapMode:
                                                            Text.WordWrap
                                                    }


                                                    Text {

                                                        anchors.horizontalCenter:
                                                            parent.horizontalCenter

                                                        text:
                                                            String(
                                                                modelData.value
                                                            )

                                                        color:
                                                            textPrimary

                                                        font.pixelSize:
                                                            16

                                                        font.bold:
                                                            true
                                                    }
                                                }
                                            }
                                        }
                                    }


                                    // ---------------------------------
                                    // CHANNEL LIST
                                    // ---------------------------------

                                    Text {

                                        text:
                                            hasNetworks
                                            ?
                                            "DETECTED CHANNELS (TOP)"
                                            :
                                            "CHANNEL STATUS"

                                        color:
                                            textSecondary

                                        font.pixelSize:
                                            12

                                        font.bold:
                                            true

                                        font.letterSpacing:
                                            1.0
                                    }


                                    Column {

                                        width:
                                            parent.width

                                        spacing:
                                            5


                                        Repeater {

                                            model:
                                                analyses.slice(
                                                    0,
                                                    3
                                                )


                                            delegate:
                                                Rectangle {

                                                width:
                                                    parent.width

                                                height:
                                                    34

                                                radius:
                                                    7

                                                color:
                                                    Number(
                                                        modelData.channel
                                                    ) ===
                                                    recommendation
                                                    ?
                                                    "#1c1012"
                                                    :
                                                    "#090b0e"

                                                border.width:
                                                    1

                                                border.color:
                                                    Number(
                                                        modelData.channel
                                                    ) ===
                                                    recommendation
                                                    ?
                                                    "#6e2024"
                                                    :
                                                    "#181b20"


                                                Row {

                                                    anchors.fill:
                                                        parent

                                                    anchors.leftMargin:
                                                        9

                                                    anchors.rightMargin:
                                                        9

                                                    spacing:
                                                        8


                                                    Text {

                                                        width:
                                                            42

                                                        text:
                                                            "CH " +
                                                            modelData.channel

                                                        color:
                                                            Number(
                                                                modelData.channel
                                                            ) ===
                                                            recommendation
                                                            ?
                                                            redBright
                                                            :
                                                            textPrimary

                                                        font.pixelSize:
                                                            11

                                                        font.bold:
                                                            true

                                                        verticalAlignment:
                                                            Text.AlignVCenter
                                                    }


                                                    Text {

                                                        width:
                                                            34

                                                        text:
                                                            Number(
                                                                modelData.networkCount
                                                            ) +
                                                            (
                                                                Number(
                                                                    modelData.networkCount
                                                                ) === 1
                                                                ?
                                                                " AP"
                                                                :
                                                                " APs"
                                                            )

                                                        color:
                                                            textSecondary

                                                        font.pixelSize:
                                                            10

                                                        verticalAlignment:
                                                            Text.AlignVCenter
                                                    }


                                                    Rectangle {

                                                        width:
                                                            parent.width -
                                                            42 -
                                                            34 -
                                                            52 -
                                                            16

                                                        height:
                                                            6

                                                        radius:
                                                            3

                                                        anchors.verticalCenter:
                                                            parent.verticalCenter

                                                        color:
                                                            "#242a32"


                                                        Rectangle {

                                                            width:
                                                                parent.width *
                                                                Math.max(
                                                                    0,
                                                                    Math.min(
                                                                        1,
                                                                        Number(
                                                                            modelData.congestionScore
                                                                        ) /
                                                                        100
                                                                    )
                                                                )

                                                            height:
                                                                parent.height

                                                            radius:
                                                                3

                                                            color:
                                                                channelCongestionColor(
                                                                    modelData.congestionScore
                                                                )
                                                        }
                                                    }


                                                    Text {

                                                        width:
                                                            52

                                                        text:
                                                            Number(
                                                                modelData.congestionScore
                                                            )

                                                        color:
                                                            channelCongestionColor(
                                                                modelData.congestionScore
                                                            )

                                                        font.pixelSize:
                                                            12

                                                        font.bold:
                                                            true

                                                        horizontalAlignment:
                                                            Text.AlignRight

                                                        verticalAlignment:
                                                            Text.AlignVCenter
                                                    }
                                                }
                                            }
                                        }


                                        Text {

                                            visible:
                                                !hasNetworks

                                            width:
                                                parent.width

                                            text:
                                                "No " +
                                                bandName +
                                                " networks detected"

                                            color:
                                                textSecondary

                                            font.pixelSize:
                                                12

                                            horizontalAlignment:
                                                Text.AlignHCenter
                                        }
                                    }
                                }
                            }
                        }
                    }


                    // =================================================
                    // FOOTNOTE
                    // =================================================

                    Rectangle {

                        width:
                            parent.width

                        height:
                            34

                        radius:
                            8

                        color:
                            "#10151b"

                        border.width:
                            1

                        border.color:
                            "#202832"


                        Text {

                            anchors.fill:
                                parent

                            anchors.leftMargin:
                                14

                            anchors.rightMargin:
                                14

                            text:
                                "Confidence reflects how clearly the latest observed scan favours the recommendation; it is not a probability or a measurement of total RF interference."

                            color:
                                textSecondary

                            font.pixelSize:
                                11

                            horizontalAlignment:
                                Text.AlignHCenter

                            verticalAlignment:
                                Text.AlignVCenter

                            wrapMode:
                                Text.WordWrap
                        }
                    }
                }
            }


            // =====================================================
            // FOOTER
            // =====================================================

            Text {

                width:
                    parent.width

                text:
                    "WiFi Monitor  •  CoreWLAN"

                horizontalAlignment:
                    Text.AlignHCenter

                color:
                    "#4e525a"

                font.pixelSize:
                    11
            }
        }
    }


    // =========================================================
    // LIVE DOT ANIMATION
    // =========================================================

    SequentialAnimation {

        running:
            wifiController.nearbyMonitoring

        loops:
            Animation.Infinite


        PropertyAnimation {

            target:
                liveDot

            property:
                "opacity"

            from:
                1.0

            to:
                0.25

            duration:
                700
        }


        PropertyAnimation {

            target:
                liveDot

            property:
                "opacity"

            from:
                0.25

            to:
                1.0

            duration:
                700
        }


        PauseAnimation {

            duration:
                1600
        }
    }
}