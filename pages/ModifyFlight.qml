import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import FluentUI

FluScrollablePage {
    id: root

    // === 0. 核心状态 ===
    property bool isEditMode: false // false: 搜索模式, true: 编辑模式
    property var currentEditingFlightId: null // 当前正在编辑的航班ID

    // === 1. 自定义组件 (来自 AddFlight) ===
    component SmartTextBox : FluTextBox {
        property string hint: ""
        cleanEnabled: false
        text: hint
        color: (text === hint && !activeFocus) ? FluTheme.fontSecondaryColor : FluTheme.fontPrimaryColor
        onActiveFocusChanged: {
            if (activeFocus) { if (text === hint) text = "" }
            else { if (text === "") text = hint }
        }
        function reset() { text = hint; focus = false }
        readonly property bool hasValidInput: text !== "" && text !== hint
    }

    // === 2. 城市数据模型 (公用) ===
    ListModel {
        id: cityModel

        ListElement { name: "北京(BJS)"; code: "BJS" }
        ListElement { name: "上海(SHA)"; code: "SHA" }
        ListElement { name: "广州(CAN)"; code: "CAN" }
        ListElement { name: "深圳(SZX)"; code: "SZX" }
        ListElement { name: "珠海(ZUH)"; code: "ZUH" }
        ListElement { name: "成都(CTU)"; code: "CTU" }
        ListElement { name: "杭州(HGH)"; code: "HGH" }
        ListElement { name: "昆明(KMG)"; code: "KMG" }
        ListElement { name: "西安(XIY)"; code: "XIY" }
        ListElement { name: "重庆(CKG)"; code: "CKG" }
        ListElement { name: "武汉(WUH)"; code: "WUH" }
        ListElement { name: "南京(NKG)"; code: "NKG" }
        ListElement { name: "厦门(XMN)"; code: "XMN" }
        ListElement { name: "长沙(CSX)"; code: "CSX" }
        ListElement { name: "海口(HAK)"; code: "HAK" }
        ListElement { name: "三亚(SYX)"; code: "SYX" }
        ListElement { name: "青岛(TAO)"; code: "TAO" }
        ListElement { name: "大连(DLC)"; code: "DLC" }
        ListElement { name: "天津(TSN)"; code: "TSN" }
        ListElement { name: "郑州(CGO)"; code: "CGO" }
        ListElement { name: "沈阳(SHE)"; code: "SHE" }
        ListElement { name: "哈尔滨(HRB)"; code: "HRB" }
        ListElement { name: "乌鲁木齐(URC)"; code: "URC" }
        ListElement { name: "贵阳(KWE)"; code: "KWE" }
        ListElement { name: "南宁(NNG)"; code: "NNG" }
        ListElement { name: "福州(FOC)"; code: "FOC" }
        ListElement { name: "兰州(LHW)"; code: "LHW" }
        ListElement { name: "太原(TYN)"; code: "TYN" }
        ListElement { name: "长春(CGQ)"; code: "CGQ" }
        ListElement { name: "南昌(KHN)"; code: "KHN" }
        ListElement { name: "呼和浩特(HET)"; code: "HET" }
        ListElement { name: "宁波(NGB)"; code: "NGB" }
        ListElement { name: "温州(WNZ)"; code: "WNZ" }
        ListElement { name: "合肥(HFE)"; code: "HFE" }
        ListElement { name: "济南(TNA)"; code: "TNA" }
        ListElement { name: "石家庄(SJW)"; code: "SJW" }
        ListElement { name: "银川(INC)"; code: "INC" }
        ListElement { name: "西宁(XNN)"; code: "XNN" }
        ListElement { name: "拉萨(LXA)"; code: "LXA" }
        ListElement { name: "丽江(LJG)"; code: "LJG" }
        ListElement { name: "西双版纳(JHG)"; code: "JHG" }
        ListElement { name: "桂林(KWL)"; code: "KWL" }
        ListElement { name: "烟台(YNT)"; code: "YNT" }
        ListElement { name: "泉州(JJN)"; code: "JJN" }
        ListElement { name: "无锡(WUX)"; code: "WUX" }
        ListElement { name: "洛阳(LYA)"; code: "LYA" }
    }

    // === 3. 辅助函数 ===
    function formatDate(d) { return Qt.formatDate(d, "yyyy-MM-dd") }

    // 提取三字码 "北京(BJS)" -> "BJS"
    function getCityCode(cityName) {
        var matches = cityName.match(/\(([^)]+)\)/);
        if (matches && matches.length > 1) return matches[1];
        return "";
    }

    // 根据三字码反查城市名 "BJS" -> "北京(BJS)"
    function getCityNameByCode(code) {
        for(var i=0; i<cityModel.count; i++){
            if(cityModel.get(i).code === code) return cityModel.get(i).name
        }
        return code // 如果找不到，直接返回代码
    }

    // ========================================================================
    //                          PART A: 搜索逻辑 (复用 FlightSearch)
    // ========================================================================

    property string searchFromCity: "珠海(ZUH)"
    property string searchToCity: "北京(BJS)"
    property date searchDate: new Date()
    property bool isSearching: false
    property bool isSelectingFrom: true // 用于弹窗判断是选出发地还是目的地

    ListModel { id: resultModel }

    function performSearch(){
        if(searchFromCity == searchToCity){ showError("出发地和目的地不能相同"); return }

        isSearching = true
        resultModel.clear()

        var xhr = new XMLHttpRequest
        var url = backendBaseUrl + "/api/search_flights"

        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.onreadystatechange = function(){
            if(xhr.readyState === XMLHttpRequest.DONE){
                isSearching = false
                if(xhr.status === 200){
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if(response.status === "success"){
                            var list = response.data || []
                            if(list.length === 0) showInfo("未找到航班")
                            for(var i = 0; i < list.length; i ++){
                                var item = list[i];
                                // 尽量把所有字段都存进去，方便回填
                                resultModel.append({
                                    "flight_id": item.id,
                                    "flight_number": item.flight_number,
                                    "airline": item.airline,
                                    "aircraft_model": item.aircraft_model,
                                    "departure_time": item.departure_time,
                                    "landing_time": item.landing_time,
                                    "dep_code": getCityCode(searchFromCity), // 记录代码方便回填
                                    "arr_code": getCityCode(searchToCity),
                                    "departure_date": item.departure_date || formatDate(searchDate), // 后端可能没返日期，用搜索日期兜底
                                    "price": item.price,
                                    // 如果后端搜索列表返回了详细库存，这里可以接；如果没有，编辑时可能需要手动填或单独查详情
                                    "economy_seats": item.economy_seats || 0,
                                    "economy_price": item.economy_price || item.price || 0,
                                    "business_seats": item.business_seats || 0,
                                    "business_price": item.business_price || 0,
                                    "first_class_seats": item.first_class_seats || 0,
                                    "first_class_price": item.first_class_price || 0
                                })
                            }
                        } else {
                            showError(response.message || "查询失败")
                        }
                    } catch(e){
                        console.log(e); showError("数据解析失败")
                    }
                } else {
                    showError("服务器连接失败：" + xhr.status)
                }
            }
        }

        var requestData = {
            "departure_city": getCityCode(searchFromCity),
            "arrival_city": getCityCode(searchToCity),
            "departure_date": formatDate(searchDate),
            "seat_class": "经济舱" // 管理员搜索默认查经济舱即可
        }
        xhr.send(JSON.stringify(requestData))
    }

    // 进入编辑模式，回填数据
    function startEdit(flightData) {
        currentEditingFlightId = flightData.flight_id

        // 1. 回填文本框
        inputFlightNo.text = flightData.flight_number
        inputAirline.text = flightData.airline
        inputModel.text = flightData.aircraft_model

        inputDepTime.text = flightData.departure_time
        inputArrTime.text = flightData.landing_time

        // 2. 回填库存和价格 (注意：如果搜索列表没返回这些，这里会是0，需要手动填)
        inputEcoSeats.text = flightData.economy_seats
        inputEcoPrice.text = flightData.economy_price
        inputBusSeats.text = flightData.business_seats
        inputBusPrice.text = flightData.business_price
        inputFirstSeats.text = flightData.first_class_seats
        inputFirstPrice.text = flightData.first_class_price

        // 3. 回填城市和日期
        // 尝试通过代码反查城市名，以保持UI一致
        originCity = getCityNameByCode(flightData.dep_code)
        destCity = getCityNameByCode(flightData.arr_code)

        // 解析日期字符串 "yyyy-MM-dd" 到 Date 对象
        depDate = new Date(flightData.departure_date)
        // 简单处理：假设降落日期和起飞日期大多数情况相同，或者是第二天
        // 严谨做法是后端返回 landing_date。这里暂且设为和起飞一样，管理员需手动核对
        arrDate = new Date(flightData.departure_date)

        isEditMode = true
    }

    // ========================================================================
    //                          PART B: 编辑逻辑 (复用 AddFlight)
    // ========================================================================

    // 编辑表单的状态
    property string originCity: "选择出发地"
    property string destCity: "选择目的地"
    property date depDate: new Date()
    property date arrDate: new Date()
    property bool isSelectingOriginEdit: true // 编辑模式下的城市选择判断

    // 提交修改
    function submitUpdate() {
        if (!currentEditingFlightId) { showError("航班ID丢失"); return }



        var xhr = new XMLHttpRequest()
        var url = backendBaseUrl + "/api/admin/update_flight" // 假设的更新接口
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var response = JSON.parse(xhr.responseText)
                    if (response.status === "success") {
                        showSuccess("航班修改成功")
                        isEditMode = false // 返回搜索页
                        performSearch()    // 刷新列表
                    } else {
                        showError(response.message || "修改失败")
                    }
                } else {
                    showError("服务器错误 " + xhr.status)
                }
            }
        }


        var requestData = {
            "flight_id": currentEditingFlightId, // 关键：带上ID
            "flight_number": inputFlightNo.text,
            "origin": getCityCode(originCity),
            "destination": getCityCode(destCity),
            "departure_date": formatDate(depDate),
            "departure_time": inputDepTime.text,
            "landing_date": formatDate(arrDate),
            "landing_time": inputArrTime.text,
            "airline": inputAirline.text,
            "aircraft_model": inputModel.text,
            "economy_seats": Number(inputEcoSeats.text),
            "economy_price": Number(inputEcoPrice.text),
            "business_seats": Number(inputBusSeats.text),
            "business_price": Number(inputBusPrice.text),
            "first_class_seats": Number(inputFirstSeats.text),
            "first_class_price": Number(inputFirstPrice.text)
        }
        xhr.send(JSON.stringify(requestData))
    }

    // 删除航班
    function deleteFlight() {
        // 二次确认逻辑建议在这里加（FluentUI可能有 MessageDialog，这里简化直接删）

        var xhr = new XMLHttpRequest()
        var url = backendBaseUrl + "/api/admin/delete_flight" // 假设的删除接口
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var response = JSON.parse(xhr.responseText)
                    if (response.status === "success") {
                        showSuccess("航班已删除")
                        isEditMode = false
                        performSearch() // 刷新列表
                    } else {
                        showError(response.message || "删除失败")
                    }
                } else {
                    showError("服务器错误 " + xhr.status)
                }
            }
        }
        var data = { "flight_id": currentEditingFlightId }
        xhr.send(JSON.stringify(data))
    }

    // ========================================================================
    //                          界面布局
    // ========================================================================

    ColumnLayout {
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        width: Math.min(root.width * 0.9, 1200)
        spacing: 20
        Layout.topMargin: 20

        // --------------------------------------------------------------------
        //  VIEW 1: 搜索面板 (仅在 !isEditMode 时显示)
        // --------------------------------------------------------------------
        ColumnLayout {
            visible: !isEditMode
            Layout.fillWidth: true
            spacing: 20

            // 1. 搜索条件卡片
            FluFrame {
                Layout.fillWidth: true
                padding: 20
                Layout.preferredHeight: 100 // 简单固定高度

                RowLayout {
                    anchors.fill: parent
                    spacing: 15

                    // 出发地
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 50
                        color: FluTheme.dark ? Qt.rgba(1,1,1,0.1) : "#f5f7fa"; radius: 6
                        MouseArea {
                            id: btnSearchFrom
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                isSelectingFrom = true
                                cityPopup.parent = btnSearchFrom // 挂载弹窗
                                cityPopup.open()
                            }
                            Column {
                                anchors.centerIn: parent
                                Text { text: "出发地"; color: "#888"; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: searchFromCity; font.bold: true; font.pixelSize: 16; color: FluTheme.fontPrimaryColor; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                        }
                    }

                    // 目的地
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 50
                        color: FluTheme.dark ? Qt.rgba(1,1,1,0.1) : "#f5f7fa"; radius: 6
                        MouseArea {
                            id: btnSearchTo
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                isSelectingFrom = false
                                cityPopup.parent = btnSearchTo
                                cityPopup.open()
                            }
                            Column {
                                anchors.centerIn: parent
                                Text { text: "目的地"; color: "#888"; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: searchToCity; font.bold: true; font.pixelSize: 16; color: FluTheme.fontPrimaryColor; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                        }
                    }

                    // 日期
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 50
                        color: FluTheme.dark ? Qt.rgba(1,1,1,0.1) : "#f5f7fa"; radius: 6
                        Column {
                            anchors.centerIn: parent
                            Text { text: "出发日期"; color: "#888"; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: formatDate(searchDate); font.bold: true; font.pixelSize: 16; color: FluTheme.fontPrimaryColor; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                        FluCalendarPicker { anchors.fill: parent; opacity: 0; onAccepted: { searchDate = current } }
                    }

                    // 搜索按钮
                    FluFilledButton {
                        text: "查询航班"
                        Layout.preferredHeight: 50
                        Layout.preferredWidth: 120
                        font.bold: true
                        font.pixelSize: 16
                        onClicked: performSearch()
                    }
                }
            }

            // 2. 搜索结果列表
            ListView {
                id: resultList
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                implicitHeight: 600
                model: resultModel
                spacing: 10
                clip: true

                delegate: FluFrame {
                    width: resultList.width
                    height: 90
                    padding: 15

                    RowLayout {
                        anchors.fill: parent
                        spacing: 20

                        // 左侧信息
                        Column {
                            Layout.preferredWidth: 150
                            Text { text: model.airline; font.bold: true; font.pixelSize: 16; color: FluTheme.fontPrimaryColor }
                            Text { text: model.flight_number + " | " + model.aircraft_model; color: "#888" }
                        }

                        // 中间时间
                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            RowLayout {
                                anchors.centerIn: parent; spacing: 30
                                Text { text: model.departure_time; font.pixelSize: 22; font.bold: true; color: FluTheme.fontPrimaryColor }
                                Column {
                                    Rectangle { width: 50; height: 2; color: "#ccc" }
                                    Text { text: "修改"; font.pixelSize: 10; color: "#ccc"; anchors.horizontalCenter: parent.horizontalCenter }
                                }
                                Text { text: model.landing_time; font.pixelSize: 22; font.bold: true; color: FluTheme.fontPrimaryColor }
                            }
                        }

                        // 右侧操作
                        FluFilledButton {
                            text: "编辑 / 修改"
                            onClicked: {
                                // 触发编辑
                                startEdit(model)
                            }
                        }
                    }
                }
            }
        }


        // --------------------------------------------------------------------
        //  VIEW 2: 编辑面板 (仅在 isEditMode 时显示)
        // --------------------------------------------------------------------
        FluFrame {
            visible: isEditMode
            Layout.fillWidth: true
            padding: 24

            ColumnLayout {
                anchors.fill: parent
                spacing: 20

                // 顶部操作栏
                RowLayout {
                    FluIconButton {
                        iconSource: FluentIcons.ChromeBack
                        onClicked: isEditMode = false
                    }
                    Text { text: "正在编辑航班: " + inputFlightNo.text; font.bold: true; color: "#666" }
                    Item { Layout.fillWidth: true }

                    // 删除按钮 (危险操作，红色)
                    FluFilledButton {
                        text: "删除此航班"
                        normalColor: "#FF4D4F"
                        hoverColor: "#D9363E"
                        textColor: "white"
                        onClicked: deleteFlight()
                    }
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: "#eee" }

                // --- 1. 基本信息 ---
                FluText { text: "基本信息"; font.bold: true }
                RowLayout {
                    Layout.fillWidth: true; spacing: 15
                    SmartTextBox { id: inputFlightNo; hint: "航班号"; Layout.fillWidth: true }
                    SmartTextBox { id: inputAirline; hint: "航空公司"; Layout.fillWidth: true }
                    SmartTextBox { id: inputModel; hint: "机型"; Layout.fillWidth: true }
                }

                // --- 2. 航线与时间 ---
                FluText { text: "航线与时间"; font.bold: true }
                RowLayout {
                    Layout.fillWidth: true; spacing: 15

                    // 始发地
                    Rectangle {
                        Layout.fillWidth: true; height: 40; radius: 4
                        color: FluTheme.dark ? Qt.rgba(1,1,1,0.1) : "#f5f7fa"; border.color: "#e0e0e0"
                        MouseArea {
                            id: btnEditOrigin
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { isSelectingOriginEdit = true; cityPopup.parent = btnEditOrigin; cityPopup.open() }
                            Text { anchors.centerIn: parent; text: originCity; color: FluTheme.fontPrimaryColor }
                        }
                    }
                    FluIcon { iconSource: FluentIcons.Forward; color: "#ccc" }
                    // 目的地
                    Rectangle {
                        Layout.fillWidth: true; height: 40; radius: 4
                        color: FluTheme.dark ? Qt.rgba(1,1,1,0.1) : "#f5f7fa"; border.color: "#e0e0e0"
                        MouseArea {
                            id: btnEditDest
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { isSelectingOriginEdit = false; cityPopup.parent = btnEditDest; cityPopup.open() }
                            Text { anchors.centerIn: parent; text: destCity; color: FluTheme.fontPrimaryColor }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true; spacing: 15
                    // 起飞时间
                    RowLayout {
                        Layout.fillWidth: true
                        Rectangle {
                            Layout.fillWidth: true; height: 34; radius: 4; border.color: "#ccc"
                            Text { anchors.centerIn: parent; text: formatDate(depDate); color: FluTheme.fontPrimaryColor }
                            FluCalendarPicker { anchors.fill: parent; opacity: 0; onAccepted: depDate = current }
                        }
                        SmartTextBox { id: inputDepTime; hint: "起飞时间(HH:mm)"; Layout.preferredWidth: 100 }
                    }
                    // 降落时间
                    RowLayout {
                        Layout.fillWidth: true
                        Rectangle {
                            Layout.fillWidth: true; height: 34; radius: 4; border.color: "#ccc"
                            Text { anchors.centerIn: parent; text: formatDate(arrDate); color: FluTheme.fontPrimaryColor }
                            FluCalendarPicker { anchors.fill: parent; opacity: 0; onAccepted: arrDate = current }
                        }
                        SmartTextBox { id: inputArrTime; hint: "降落时间(HH:mm)"; Layout.preferredWidth: 100 }
                    }
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: "#eee" }

                // --- 3. 舱位库存与价格 ---
                FluText { text: "舱位库存与价格"; font.bold: true }
                GridLayout {
                    columns: 4; rowSpacing: 10; columnSpacing: 15; Layout.fillWidth: true

                    Text { text: ""; Layout.preferredWidth: 60 }
                    Text { text: "座位数"; font.bold: true; Layout.fillWidth: true }
                    Text { text: "价格 (¥)"; font.bold: true; Layout.fillWidth: true }
                    Item { Layout.fillWidth: true }

                    Text { text: "经济舱"; Layout.alignment: Qt.AlignRight }
                    SmartTextBox { id: inputEcoSeats; hint: "库存" }
                    SmartTextBox { id: inputEcoPrice; hint: "价格" }
                    Item { Layout.fillWidth: true }

                    Text { text: "商务舱"; Layout.alignment: Qt.AlignRight }
                    SmartTextBox { id: inputBusSeats; hint: "库存" }
                    SmartTextBox { id: inputBusPrice; hint: "价格" }
                    Item { Layout.fillWidth: true }

                    Text { text: "头等舱"; Layout.alignment: Qt.AlignRight }
                    SmartTextBox { id: inputFirstSeats; hint: "库存" }
                    SmartTextBox { id: inputFirstPrice; hint: "价格" }
                    Item { Layout.fillWidth: true }
                }

                Item { Layout.preferredHeight: 20 }

                // 提交按钮
                FluFilledButton {
                    text: "保存修改"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    font.bold: true
                    font.pixelSize: 16
                    onClicked: submitUpdate()
                }
            }
        }
    }

    // === 弹窗：城市选择 (共用) ===
    Popup {
        id: cityPopup
        y: parent.height + 5
        x: (parent.width - width) / 2
        width: 300
        height: 400
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            color: FluTheme.dark ? "#2d2d2d" : "#ffffff"
            radius: 8
            border.color: FluTheme.dark ? "#444" : "#e4e4e4"
            FluShadow { radius: 8 }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // 标题栏动态变化
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 40
                color: "transparent"
                Text {
                    anchors.centerIn: parent;
                    // 判断当前是【搜索模式】还是【编辑模式】，决定显示什么标题
                    text: {
                        if (!isEditMode) return isSelectingFrom ? "选择出发城市" : "选择到达城市"
                        else return isSelectingOriginEdit ? "修改出发城市" : "修改到达城市"
                    }
                    font.bold: true
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#eee" }
            }

            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                model: cityModel
                delegate: Rectangle {
                    width: parent.width; height: 40; color: "transparent"
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            // 逻辑分叉：搜索模式 vs 编辑模式
                            if (!isEditMode) {
                                if (isSelectingFrom) searchFromCity = model.name
                                else searchToCity = model.name
                            } else {
                                if (isSelectingOriginEdit) originCity = model.name
                                else destCity = model.name
                            }
                            cityPopup.close()
                        }
                        Rectangle { anchors.fill: parent; color: FluTheme.primaryColor; opacity: parent.containsMouse ? 0.1 : 0 }
                    }
                    Text { anchors.left: parent.left; anchors.leftMargin: 20; anchors.verticalCenter: parent.verticalCenter; text: model.name; color: FluTheme.fontPrimaryColor }
                }
            }
        }
    }
}
