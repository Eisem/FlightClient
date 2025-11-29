import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import FluentUI

FluScrollablePage {
    id: root

    // signal searchFlightSuccess(var FlightList)

    // --- 0. 模拟城市数据模型 ---
    ListModel {
        id: cityModel
        ListElement { name: "珠海(ZUH)"; code: "ZUH" }
        ListElement { name: "北京(BJS)"; code: "BJS" }
        ListElement { name: "上海(SHA)"; code: "SHA" }
        ListElement { name: "广州(CAN)"; code: "CAN" }
        ListElement { name: "深圳(SZX)"; code: "SZX" }
        ListElement { name: "成都(CTU)"; code: "CTU" }
    }

    // === 内部状态 ===
    property string fromCity: "珠海(ZUH)"
    property string toCity: "北京(BJS)"
    property date departureDate: new Date()
    property date returnDate: new Date()
    property bool isRoundTrip: radioRoundTrip.checked
    property string selectedClass: comboClass.currentText
    property bool isSelectingFrom: true
    property bool isSearching: false // 标记搜索状态，用于禁用按钮防止重复点击

    // 格式化日期：2025-11-28
    function formatDate(d) {
        return Qt.formatDate(d, "yyyy-MM-dd")
    }

    function swapCities() {
        var temp = fromCity; fromCity = toCity; toCity = temp
    }

    // 辅助函数：从 "珠海(ZUH)" 中提取 "ZUH"
    function getCityCode(cityName) {
        var matches = cityName.match(/\(([^)]+)\)/);
        if (matches && matches.length > 1) {
            return matches[1];
        }
        return ""; // 没找到代码
    }

    ListModel {id: resultModel}

    // 往返逻辑控制 0 -> 单程, 1 -> 去程, 2 -> 返程
    property int searchStep: 0
    // 暂存第一程保存的航班数据
    property var firstLegData: null

    function handleSelectFlight(flightData){
        if(searchStep === 0){
            console.log("单程下单：", flightData.flight_no)
            showSuccess("已选择航班: " + flightData.flight_no)
            // 这里可以发射信号跳转到下单页
            // root.searchFlightSuccess([flightData])
        }else if(searchStep === 1){
            // [往返-第1步] 存下去程，查返程
            firstLegData = flightData
            searchStep = 2 // 进入第2步
            resultModel.clear() // 清空列表，准备显示返程

            showSuccess("去程已选 " + flightData.flight_no + "，正在查询返程...")

            // 发起返程搜索：交换城市，使用返回日期
            performSearchInternal(toCity, fromCity, returnDate)
        }else if(searchStep === 2){
            // [往返-第2步] 完成，提交两程数据
            console.log("往返下单: 去程" + firstLegData.flight_no + " + 返程" + flightData.flight_no)
            showSuccess("往返行程已确认！")
            // 发射信号，传出两个航班的数据数组
            // root.searchFlightSuccess([firstLegData, flightData])
        }
    }

    function performSearch(){
        // 出发地 == 目的地
        if(fromCity == toCity){
            showError("出发地和目的地不能相同")
            return
        }

        if(isRoundTrip){
            searchStep = 1 // 往返模式，从第一步开始
        }else{
            searchStep = 0 // 单程模式
        }

        // 发起正常的去程查询
        performSearchInternal(fromCity, toCity, departureDate)
    }

    function performSearchInternal(){
        isSearching = true
        console.log("开始搜索航班")
        resultModel.clear() // 先清空旧结果

        var xhr = new XMLHttpRequest
        var url = backendBaseUrl + "/api/search_flights"
        console.log("请求地址：" + url)
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.onreadystatechange = function(){
            if(xhr.readyState === XMLHttpRequest.DONE){
                isSearching = false // 搜索完成， 解锁状态
                if(xhr.status === 200){
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if(response.status === "success"){
                            var list = response.data || []
                            if(list.length === 0) showInfo("未找到航班")
                            for(var i = 0; i < list.length; i ++){
                                resultModel.append(list[i])
                            }
                        } else {
                            showerror(response.message || "查询失败")
                        }
                    } catch(e){
                        console.log("Json解析失败")
                        showError("数据解析失败")
                    }
                }else{
                    // 处理 http 错误
                    console.log("服务器连接失败")
                    showError("服务器连接失败：" + xhr.status)
                    // 【调试用】如果后端没通，我们可以伪造一个成功信号，方便你写下一个界面
                    // 实际发布时请删掉下面这行
                    mockData();
                }
            }
        }

        var requestData = {
            "departure_city": getCityCode(fromCity), // 提取 ZUH
            "arrival_city": getCityCode(toCity),     // 提取 BJS
            "departure_date": formatDate(departureDate),
            "trip_type": "one_way",
            "seat_class": selectedClass
        }
        console.log("发送航班搜索数据：", JSON.stringify(requestData))
        xhr.send(JSON.stringify(requestData))
    }


    // 【调试用】模拟数据函数（后端没写好时可以用这个）
    function mockData(){
        var basePrice = (searchStep === 2) ? 1500 : 980 // 返程贵一点以便区分
            resultModel.append({ "flight_no": "CA1234", "airline": "模拟航空", "plane":"737", "dep_time": "08:00", "arr_time": "11:00", "dep_airport":"T1", "arr_airport":"T2", "price": basePrice })
            resultModel.append({ "flight_no": "CZ5678", "airline": "模拟航空", "plane":"320", "dep_time": "14:30", "arr_time": "17:30", "dep_airport":"T1", "arr_airport":"T2", "price": basePrice + 200 })
    }

    // === 主布局 ===
    ColumnLayout {
        Layout.topMargin: 20
        Layout.alignment: Qt.AlignVCenter
        // 限制最大宽度，防止在超宽屏上太扁
        // Layout.maximumWidth: 1200
        spacing: 0

        // 2. 核心搜索卡片
        FluFrame {
            Layout.fillWidth: true
            // 高度自适应，不再写死
            Layout.preferredHeight: contentCol.implicitHeight + 40
            padding: 20
            radius: 8
            // 允许下拉菜单和阴影超出边框
            clip: false

            ColumnLayout {
                id: contentCol
                anchors.fill: parent
                spacing: 20

                // --- 第一行：单程/往返 + 舱位 ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    FluRadioButton { id: radioOneWay; text: "单程"; checked: true }
                    FluRadioButton { id: radioRoundTrip; text: "往返" }
                    Item { Layout.fillWidth: true } // 占位弹簧

                    // 舱位选择
                    FluComboBox {
                        id: comboClass
                        width: 140
                        model: ["经济舱", "公务/头等舱"]
                        currentIndex: 0
                        z: 999 // 保证下拉菜单在最上层
                    }
                }

                // --- 第二行：城市 + 日期 (核心修复区域) ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15

                    // ===========================
                    // 1. 城市选择块 (左侧)
                    // ===========================
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        Layout.minimumWidth: 200
                        color: FluTheme.dark ? Qt.rgba(255,255,255,0.05) : "#f5f7fa"
                        radius: 6
                        border.color: FluTheme.dark ? "#333" : "#e0e0e0"

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            // 1.1 出发地
                            MouseArea {
                                id: btnFrom // 【新增】给它一个ID，方便定位
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.isSelectingFrom = true
                                    // 【核心修改】将弹窗挂载到当前点击的区域下
                                    cityPopup.parent = btnFrom
                                    cityPopup.open()
                                }
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "出发地"
                                        color: "#888"
                                        font.pixelSize: 12
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: root.fromCity
                                        font.bold: true
                                        font.pixelSize: 18
                                        color: FluTheme.fontPrimaryColor
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }

                            // 交换图标
                            FluIconButton {
                                iconSource: FluentIcons.Switch
                                iconSize: 16
                                onClicked: swapCities()
                            }

                            // 1.2 目的地
                            MouseArea {
                                id: btnTo // 【新增】给它一个ID
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.isSelectingFrom = false
                                    // 【核心修改】将弹窗挂载到当前点击的区域下
                                    cityPopup.parent = btnTo
                                    cityPopup.open()
                                }
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "目的地"
                                        color: "#888"
                                        font.pixelSize: 12
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: root.toCity
                                        font.bold: true
                                        font.pixelSize: 18
                                        color: FluTheme.fontPrimaryColor
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                        }
                    }

                    // 2. 日期选择块 (右侧)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        Layout.minimumWidth: 200
                        color: FluTheme.dark ? Qt.rgba(255,255,255,0.05) : "#f5f7fa"
                        radius: 6
                        border.color: FluTheme.dark ? "#333" : "#e0e0e0"

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            // ===========================
                            // 2.1 出发日期
                            // ===========================
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                // 1. 视觉层：显示文字（用户看到的）
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "出发日期"
                                        color: "#888"
                                        font.pixelSize: 12
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: formatDate(root.departureDate)
                                        font.bold: true
                                        font.pixelSize: 18
                                        color: FluTheme.fontPrimaryColor
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                // 2. 交互层：隐形遮罩（用户实际点的）
                                FluCalendarPicker {
                                    id: pickerDepart
                                    anchors.fill: parent // 铺满整个区域
                                    opacity: 0           // 【关键】完全透明，让它不可见
                                    z: 10                // 保证在最上层，能接收点击

                                    onAccepted: {
                                        root.departureDate = current
                                        // FluCalendarPicker 选完日期后会自动关闭弹窗
                                    }
                                }
                            }

                            // 分隔线
                            Rectangle { width: 1; height: 30; color: "#ccc" }

                            // ===========================
                            // 2.2 返回日期
                            // ===========================
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                // 1. 视觉层
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "返回日期"
                                        color: "#888"
                                        font.pixelSize: 12
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: root.isRoundTrip ? formatDate(root.returnDate) : "—"
                                        font.bold: true
                                        font.pixelSize: 18
                                        color: FluTheme.fontPrimaryColor
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                // 2. 交互层：隐形遮罩
                                FluCalendarPicker {
                                    id: pickerReturn
                                    anchors.fill: parent
                                    opacity: 0 // 透明
                                    z: 10

                                    // 只有往返时才启用
                                    visible: root.isRoundTrip

                                    onAccepted: {
                                        if (current < root.departureDate) {
                                            showError("返回日期不能早于出发日期")
                                            return
                                        }
                                        root.returnDate = current
                                    }
                                }

                                // 禁用时的鼠标样式（可选）
                                MouseArea {
                                    anchors.fill: parent
                                    visible: !root.isRoundTrip
                                    cursorShape: Qt.ForbiddenCursor
                                }
                            }
                        }
                    }

                    // 3. 搜索按钮 (跟在日期后面)
                    FluFilledButton {
                        Layout.preferredHeight: 60 // 高度跟输入框对齐
                        Layout.preferredWidth: 120 // 固定宽度
                        text: "搜索"
                        normalColor: "#FF9500"
                        hoverColor: "#E68600"
                        textColor: "white"
                        font.pixelSize: 18
                        font.bold: true

                        disabled: root.isSearching
                        onClicked: {
                            performSearch()
                        }
                    }
                }
            }
        }

        // =========================================
        // 往返进度条 (仿照你提供的截图2)
        // =========================================
        Item {
            id: flightProgressBar

            // 1. 布局设置：不占满全屏，居中，宽度70%
            Layout.fillWidth: false
            Layout.preferredWidth: parent.width * 0.7
            // Layout.alignment: Qt.AlignHCenter

            // 2. 显示与高度控制
            Layout.topMargin: searchStep > 0 ? 15 : 0
            Layout.preferredHeight: searchStep > 0 ? 56 : 0
            visible: searchStep > 0

            // 3. 统一的阴影背景（放在最底下，这样中间不会有阴影重叠线）
            FluShadow {
                anchors.fill: bgRow
                radius: 10 // 圆角要和下面的 Rectangle 保持一致
                elevation: 3
                color: "#33000000"
            }

            // 4. 内容容器
            RowLayout {
                id: bgRow
                anchors.fill: parent
                spacing: 0 // 间距设为0，让它们无缝连接

                // =========================================
                // 左边部分：去程
                // =========================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // 设置圆角（四个角都变圆）
                    radius: 10
                    color: searchStep === 1 ? "#F0F9FF" : "#FFFFFF"

                    // 【补丁】只盖住右边！
                    // 作用：把右边的圆角变成直角，以便和右边的块连接
                    Rectangle {
                        width: 20
                        height: parent.height
                        anchors.right: parent.right // 靠右贴紧
                        color: parent.color         // 颜色和本体一样
                    }

                    // --- 内部文字内容 ---
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle {
                            width: 34; height: 20; radius: 4
                            color: searchStep === 1 ? "#0086F6" : "#F0F0F0"
                            Text { anchors.centerIn: parent; text: "去程"; font.pixelSize: 11; color: searchStep===1?"#FFF":"#999" }
                        }
                        Text {
                            text: fromCity + " ➔ " + toCity
                            font.bold: true
                            font.pixelSize: 14
                            color: searchStep === 1 ? "#333" : "#999"
                        }
                    }

                    // 点击切回第一步
                    MouseArea {
                        anchors.fill: parent
                        enabled: searchStep === 2
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { /* 你的逻辑 */ }
                    }
                }

                // =========================================
                // 中间分割线 (可选)
                // =========================================
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 20
                    Layout.alignment: Qt.AlignVCenter
                    color: "#E0E0E0"
                    z: 1 // 确保线在最上层
                }

                // =========================================
                // 右边部分：返程
                // =========================================
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // 设置圆角（四个角都变圆）
                    radius: 10
                    color: searchStep === 2 ? "#F0F9FF" : "#FFFFFF"

                    // 只盖住左边！
                    // 作用：把左边的圆角变成直角，去接左边的块。
                    Rectangle {
                        width: 20
                        height: parent.height
                        anchors.left: parent.left   // 靠左贴紧
                        color: parent.color         // 颜色和本体一样
                    }

                    // --- 内部文字内容 ---
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle {
                            width: 34; height: 20; radius: 4
                            color: searchStep === 2 ? "#0086F6" : "#F0F0F0"
                            Text { anchors.centerIn: parent; text: "返程"; font.pixelSize: 11; color: searchStep===2?"#FFF":"#999" }
                        }
                        Text {
                            text: toCity + " ➔ " + fromCity
                            font.bold: true
                            font.pixelSize: 14
                            color: searchStep === 2 ? "#333" : "#999"
                        }
                    }
                }
            }
        }

        // =========================================
        // 搜索结果列表
        // =========================================
        ListView {
            id: resultList
            Layout.fillWidth: true

            Layout.topMargin: searchStep > 0 ? 6 : 20
            // 高度自适应内容
            Layout.preferredHeight: contentHeight
            interactive: false // 禁用内部滚动，让外层 ScrollablePage 滚动

            model: resultModel
            spacing: 8
            clip: true

            delegate: Rectangle {
                width: resultList.width
                height: 80
                radius: 6
                color: FluTheme.dark ? Qt.rgba(32/255, 32/255, 32/255, 1) : "#FFFFFF"
                border.color: FluTheme.dark ? "#333" : "#E0E0E0"
                border.width: 1
                FluShadow { radius: 6; elevation: 1 }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    // 1. 航班信息 (简单版)
                    Column {
                        Layout.preferredWidth: 120
                        Text { text: model.airline || "航司"; font.bold: true; color: FluTheme.fontPrimaryColor }
                        Text { text: (model.flight_no||"") + " " + (model.plane||""); font.pixelSize: 12; color: "#999" }
                    }

                    // 2. 时间 (中间)
                    Item { Layout.fillWidth: true; Layout.fillHeight: true
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 20
                            Text { text: model.dep_time || "00:00"; font.pixelSize: 20; font.bold: true; color: FluTheme.fontPrimaryColor }
                            Column{
                                Rectangle { width: 40; height: 1; color: "#ccc" }
                                Text { text: "直飞"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter; color: "#ccc" }
                            }
                            Text { text: model.arr_time || "00:00"; font.pixelSize: 20; font.bold: true; color: FluTheme.fontPrimaryColor }
                        }
                    }

                    // 3. 价格与按钮
                    Column {
                        Layout.alignment: Qt.AlignRight
                        Text { text: "¥" + (model.price||"--"); color: "#FF9500"; font.pixelSize: 20; font.bold: true }

                        FluFilledButton {
                            width: 90
                            height: 30

                            // 【UI核心】根据步骤改变按钮文字
                            text: {
                                if(searchStep === 0) return "订票"
                                if(searchStep === 1) return "选为去程"
                                if(searchStep === 2) return "选为返程"
                                return "预订"
                            }

                            normalColor: "#FF9500"
                            hoverColor: "#E68600"
                            textColor: "white"

                            onClicked: {
                                // 将 model 数据打包成对象传给逻辑函数
                                var data = {
                                    "flight_no": model.flight_no,
                                    "price": model.price,
                                    "airline": model.airline,
                                    // ... 补全其他字段
                                }
                                handleSelectFlight(data)
                            }
                        }
                    }
                }
            }
        }

        // 底部留白，防止列表到底部被遮挡
        Item { Layout.preferredHeight: 40 }

    }

    // ==========================================
    // 城市选择弹窗
    // ==========================================
    Popup {
        id: cityPopup

        // 【核心修改】
        // 1. 删除 anchors.centerIn: parent
        // anchors.centerIn: parent  <-- 删除这行

        // 2. 改为相对定位
        // 因为我们在点击时动态设置了 parent，所以这里的 parent.height 就是点击区域的高度
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
            // ... 内部代码保持不变 ...
            anchors.fill: parent
            spacing: 10

            // 标题栏
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: "transparent"

                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#eee" }

                Text {
                    anchors.centerIn: parent
                    text: root.isSelectingFrom ? "选择出发城市" : "选择到达城市"
                    font.bold: true
                    font.pixelSize: 16
                    color: FluTheme.fontPrimaryColor
                }
            }

            // 城市列表
            ListView {
                id: cityListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: cityModel

                delegate: Rectangle {
                    width: cityListView.width
                    height: 45
                    color: "transparent"

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.isSelectingFrom) {
                                root.fromCity = model.name
                            } else {
                                root.toCity = model.name
                            }
                            cityPopup.close()
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: FluTheme.primaryColor
                        opacity: itemMouse.containsMouse ? 0.1 : 0
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: model.name
                        font.pixelSize: 14
                        color: FluTheme.fontPrimaryColor
                    }
                }
            }
        }
    }
}
