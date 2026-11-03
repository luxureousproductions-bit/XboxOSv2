// XboxOSv2 – what we're running on, answered once.
//
// The OS, and which Pegasus this is: stock, or Pegasus X with its extra
// features (api.frontendInfo, present on Pegasus X build 90+). Screens ask
// this object instead of probing `typeof api.x` themselves, so a feature
// check reads the same everywhere and a new one is added in one place.
// Every answer is a plain value on stock Pegasus, so nothing here can throw.
import QtQuick 2.15

QtObject {
id: platform

    // ── OS ────────────────────────────────────────────────────────────────
    readonly property string os: Qt.platform.os
    readonly property bool isAndroid: os === "android"
    readonly property bool isWindows: os === "windows"
    readonly property bool isLinux:   os === "linux"
    readonly property bool isMac:     os === "osx"

    // ── Pegasus / Pegasus X ───────────────────────────────────────────────
    readonly property var  frontendInfo: (typeof api.frontendInfo !== "undefined" && api.frontendInfo) ? api.frontendInfo : null
    readonly property bool isPegasusX: !!frontendInfo && frontendInfo.name === "Pegasus X"
    readonly property string frontendName:    frontendInfo ? (frontendInfo.name || "Pegasus") : "Pegasus"
    readonly property string frontendVersion: frontendInfo ? String(frontendInfo.version || "") : ""
    readonly property int    frontendBuild:   frontendInfo ? (parseInt(frontendInfo.build) || 0) : 0
    readonly property var    features: (frontendInfo && frontendInfo.features) ? frontendInfo.features : []
    function has(feature) { return features.indexOf(feature) >= 0; }

    // Feature checks. The API probes stay as the fallback for a Pegasus X
    // older than frontendInfo, and for anything a stock build might add.
    readonly property bool hasPdf:        has("pdf")        || typeof api.pdfPageCount === "function"
    readonly property bool hasFindManual: has("findManual") || typeof api.findManual === "function"
    readonly property bool instantReturn: has("instantReturn")   // the theme stays loaded while a game runs
    readonly property bool atomicMemory:  has("atomicMemory")    // settings saves are coalesced + atomic

    // One line for lastrun.log and the Diagnostics page.
    readonly property string frontendLine: isPegasusX
        ? frontendName + " " + frontendVersion + (frontendBuild ? " build " + frontendBuild : "")
        : "stock Pegasus"
    readonly property string featureLine: features.length ? features.join(", ") : "none"
}
