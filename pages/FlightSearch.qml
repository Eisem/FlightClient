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

    // 标记最近一次搜索是不是往返搜索（用于控制Tab栏显示）
    property bool hasSearched: false
    // 往返逻辑控制 0 -> 单程, 1 -> 去程, 2 -> 返程
    property int activeTab: 0
    // 暂存第一程保存的航班数据
    property var firstLegData: null

    // === 核心逻辑：处理点击航班 ===
    function handleSelectFlight(flightData){
        // 1. 单程模式：直接下单
        if (!isRoundTrip) {
            // 【修改】单程传参：只传 outboundFlight (去程)
            nav_view.push("qrc:/qt/qml/FlightClient/pages/BookingPage.qml", {
                "isRoundTrip": false,
                "outboundFlight": flightData, // 把单程数据作为去程
                "inboundFlight": null,        // 返程为空
                "totalPrice": flightData.price // 总价就是单程价
            })
            return
        }

        // 2. 往返模式
        if (activeTab === 0) {
            // --- 当前在选去程 ---
            firstLegData = flightData // 暂存去程数据
            showSuccess("去程已选 " + flightData.flight_number + "，正在查询返程...")

            // 切换到返程视图
            activeTab = 1
            refreshList()
        } else {
            // --- 当前在选返程 (最终下单) ---
            if(!firstLegData){
                showError("异常：去程数据丢失，请重新选择")
                activeTab = 0
                refreshList()
                return
            }

            // 【修改】往返传参：同时传递 去程(firstLegData) 和 返程(flightData)
            var sumPrice = firstLegData.price + flightData.price

            nav_view.push("qrc:/qt/qml/FlightClient/pages/BookingPage.qml", {
                "isRoundTrip": true,
                "outboundFlight": firstLegData, // 去程数据
                "inboundFlight": flightData,    // 返程数据
                "totalPrice": sumPrice          // 总价
            })
        }
    }

    // === 统一搜索入口 ===
    function performSearch(){
        if(fromCity == toCity){ showError("出发地和目的地不能相同"); return }

        if(isRoundTrip) hasSearched = true
        else hasSearched = false
        // 重置状态
        firstLegData = null
        activeTab = 0

        // 发起搜索
        refreshList()
    }

    // === 列表刷新逻辑 ===
    // 这是一个中间层，负责决定把什么参数传给 performSearchInternal
    function refreshList() {
        // 计算当前应该查什么
        var targetFrom, targetTo, targetDate

        if (!isRoundTrip) {
            // 单程
            targetFrom = fromCity
            targetTo = toCity
            targetDate = departureDate
        } else {
            // 往返：根据 activeTab 决定
            targetFrom = (activeTab === 0) ? fromCity : toCity
            targetTo   = (activeTab === 0) ? toCity   : fromCity
            targetDate = (activeTab === 0) ? departureDate : returnDate
        }

        // 调用原本的网络请求函数，传入计算好的参数
        performSearchInternal(targetFrom, targetTo, targetDate)
    }

    function performSearchInternal(currentFrom, currentTo, currentDate){
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
                root.isSearching = false
                if(xhr.status === 200){
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if(response.status === "success"){
                            var list = response.data || []
                            if(list.length === 0) showInfo("未找到航班")

                            for(var i = 0; i < list.length; i ++){
                                var item = list[i];
                                resultModel.append({
                                    "flight_number": item.flight_number,
                                    "airline": item.airline,
                                    "aircraft_model": item.aircraft_model,
                                    "departure_time": item.departure_time,
                                    "landing_time": item.landing_time,
                                    "dep_airport": currentFrom + "机场",
                                    "arr_airport": currentTo + "机场",
                                    "price": item.price,
                                    "flight_id": item.id
                                })
                            }
                        } else {
                            showError(response.message || "查询失败")
                        }
                    } catch(e){
                        console.log("Json解析失败", e) // 打印错误详情
                        showError("数据解析失败")
                    }
                }else{
                    console.log("服务器连接失败")
                    // showError("服务器连接失败：" + xhr.status)
                    mockData(); // 调试时保留，正式连后端时建议注释掉以免混淆
                }
            }
        }

        var requestData = {
            "departure_city": getCityCode(currentFrom), // 提取 ZUH
            "arrival_city": getCityCode(currentTo),     // 提取 BJS
            "departure_date": formatDate(currentDate),
            "seat_class": selectedClass
        }
        console.log("发送航班搜索数据：", JSON.stringify(requestData))
        xhr.send(JSON.stringify(requestData))
    }


    // 【调试用】模拟数据 (已修正逻辑)
    function mockData(){
        // 1. 判断是去程还是返程
        // activeTab === 0 : 去程 (from -> to)
        // activeTab === 1 : 返程 (to -> from)
        var isReturn = (isRoundTrip && activeTab === 1)

        // 2. 动态决定起降地名称
        // 注意：这里直接用前端变量 "珠海(ZUH)"，这样 BookingPage 就能解析出 "珠海"
        var currentDep = (activeTab === 0) ? fromCity : toCity
        var currentArr = (activeTab === 0) ? toCity : fromCity

        var basePrice = isReturn ? 1500 : 980

        // 3. 模拟第一条数据
        resultModel.append({
            "flight_number": isReturn ? "CA8888" : "CA1234",
            "airline": "模拟航空",
            "aircraft_model": "波音737",
            "departure_time": "08:00",
            "landing_time": "11:00",

            "dep_airport": currentDep,
            "arr_airport": currentArr,

            "price": basePrice,
            "flight_id": 1001
        })

        // 4. 模拟第二条数据
        resultModel.append({
            "flight_number": isReturn ? "CZ9999" : "CZ5678",
            "airline": "测试航空",
            "aircraft_model": "空客320",
            "departure_time": "14:30",
            "landing_time": "17:30",

            "dep_airport": currentDep,
            "arr_airport": currentArr,

            "price": basePrice + 200,
            "flight_id": 1002
        })
    }

    // === 【新增】重置所有搜索状态 ===
    function resetSearchState() {
        hasSearched = false          // 隐藏 Tab 栏
        resultModel.clear()          // 清空搜索结果列表
        firstLegData = null          // 清空已选的去程航班
        activeTab = 0                // 重置回第一步（去程）
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

                    FluRadioButton {
                        id: radioOneWay; text: "单程"; checked: true
                        onClicked: {
                            root.isRoundTrip = false
                            resetSearchState()
                        }
                    }
                    FluRadioButton {
                        id: radioRoundTrip; text: "往返"
                        onClicked: {
                            root.isRoundTrip = true
                            resetSearchState()
                        }
                    }
                    Item { Layout.fillWidth: true } // 占位弹簧

                    // 舱位选择
                    FluComboBox {
                        id: comboClass
                        width: 140
                        model: ["经济舱", "公务/头等舱"]
                        currentIndex: 0
                        z: 999 // 保证下拉菜单在最上层

                        // 用户手动切换舱位时，重置所有状态
                        onActivated: {
                            resetSearchState()
                        }
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
                                onClicked: {
                                    swapCities()
                                    resetSearchState()
                                }
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
                                        // 改了日期，重置搜索状态
                                        resetSearchState()
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
                                        // 【新增】改了日期，重置搜索状态
                                        resetSearchState()
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
            id: flightTabs

            // 1. 布局设置：不占满全屏，居中，宽度70%
            Layout.fillWidth: false
            Layout.preferredWidth: parent.width * 0.7
            // Layout.alignment: Qt.AlignHCenter

            // 2. 显示与高度控制
            Layout.topMargin: visible ? 15 : 0
            Layout.preferredHeight: visible ? 56 : 0
            visible: isRoundTrip && hasSearched

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
                    color: activeTab === 0 ? "#F0F9FF" : "#FFFFFF"

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
                            color: activeTab === 0 ? "#0086F6" : "#F0F0F0"
                            Text {
                                anchors.centerIn: parent; text: "去程"; font.pixelSize: 11;
                                color: activeTab === 0 ? "#FFF" : "#999"
                            }
                        }
                        Text {
                            // 标题：始终显示当前存储的第一程数据（如果有的话）
                            text: firstLegData ? (fromCity + "➔" + toCity + " ("+firstLegData.flight_number+")") : (fromCity + " ➔ " + toCity)
                            font.bold: activeTab === 0
                            color: activeTab === 0 ? "#0086F6" : "#666"
                        }
                    }

                    // 【去程点击逻辑】
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if(activeTab !== 0) {
                                // 仅仅切换视图，不要清空 firstLegData！
                                activeTab = 0
                                refreshList()
                            }
                        }
                    }
                }

                // =========================================
                // 中间分割线 (可选)
                // =========================================
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 30
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
                    // 样式：当前是返程页时高亮
                    color: activeTab === 1 ? "#F0F9FF" : "#FFFFFF"

                    // 只盖住左边！
                    // 作用：把左边的圆角变成直角，去接左边的块。
                    Rectangle {
                        width: 20
                        height: parent.height
                        anchors.left: parent.left   // 靠左贴紧
                        color: parent.color         // 颜色和本体一样
                    }

                    // 【核心逻辑】能否点击返程？
                    // 只要 firstLegData 还在（说明用户选过，或者没清除），就可以点回去！
                    // 不管 activeTab 现在是 0 还是 1
                    property bool canSwitchToReturn: firstLegData !== null

                    // --- 内部文字内容 ---
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        // 如果不能点，变半透明
                        opacity: parent.canSwitchToReturn ? 1 : 0.5

                        Rectangle {
                            width: 34; height: 20; radius: 4
                            color: activeTab === 1 ? "#0086F6" : "#F0F0F0"
                            Text {
                                anchors.centerIn: parent; text: "返程"; font.pixelSize: 11;
                                color: activeTab === 1 ? "#FFF" : "#999"
                            }
                        }
                        Text {
                            text: toCity + " ➔ " + fromCity
                            font.bold: activeTab === 1
                            color: activeTab === 1 ? "#0086F6" : "#666"
                        }
                    }

                    // 【返程点击逻辑】
                    MouseArea {
                        anchors.fill: parent
                        // 根据是否可选，显示手型或禁止符号
                        cursorShape: parent.canSwitchToReturn ? Qt.PointingHandCursor : Qt.ForbiddenCursor

                        onClicked: {
                            // 只有当有去程数据时，才允许切回返程
                            if(parent.canSwitchToReturn && activeTab !== 1) {
                                activeTab = 1
                                refreshList() // 刷新列表，显示返程航班
                            }
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
            Layout.fillWidth: true; Layout.topMargin: flightTabs.visible ? 2 : 10; Layout.preferredHeight: contentHeight
            interactive: false; model: resultModel; spacing: 8; clip: true

            delegate: Rectangle {
                width: resultList.width; height: 80; radius: 6
                color: FluTheme.dark ? Qt.rgba(32/255, 32/255, 32/255, 1) : "#FFFFFF"

                // 【高亮逻辑】
                property bool isSelectedOutbound: isRoundTrip && (activeTab === 0) && firstLegData && (firstLegData.flight_number === model.flight_number)
                border.color: isSelectedOutbound ? "#0086F6" : (FluTheme.dark ? "#333" : "#E0e0e0")
                border.width: isSelectedOutbound ? 2 : 1
                FluShadow { radius: 6; elevation: 1 }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 15; spacing: 10
                    Column {
                        Layout.preferredWidth: 120
                        Text { text: model.airline; font.bold: true; color: FluTheme.fontPrimaryColor }
                        Text { text: model.flight_number + " " + model.aircraft_model; font.pixelSize: 12; color: "#999" }
                    }
                    Item { Layout.fillWidth: true; Layout.fillHeight: true
                        RowLayout {
                            anchors.centerIn: parent; spacing: 20
                            Text { text: model.departure_time; font.pixelSize: 20; font.bold: true; color: FluTheme.fontPrimaryColor }
                            Column{ Rectangle{width:40;height:1;color:"#ccc"} Text{text:"直飞";font.pixelSize:10;anchors.horizontalCenter:parent.horizontalCenter;color:"#ccc"} }
                            Text { text: model.landing_time; font.pixelSize: 20; font.bold: true; color: FluTheme.fontPrimaryColor }
                        }
                    }
                    Column {
                        Layout.alignment: Qt.AlignRight
                        Text { text: "¥" + model.price; color: "#FF9500"; font.pixelSize: 20; font.bold: true }
                        FluFilledButton {
                            width: 90; height: 30
                            text: {
                                if(!isRoundTrip) return "预订"
                                if(activeTab === 0) return isSelectedOutbound ? "已选" : "选为去程"
                                return "预订"
                            }
                            normalColor: isSelectedOutbound ? "#ccc" : "#FF9500"
                            disabled: isSelectedOutbound
                            onClicked: {
                                var data = {
                                    "flight_number": model.flight_number,
                                    "price": model.price,
                                    "airline": model.airline,
                                    "aircraft_model": model.aircraft_model,
                                    "departure_time": model.departure_time,
                                    "landing_time": model.landing_time,
                                    "dep_airport": model.dep_airport,
                                    "arr_airport": model.arr_airport,
                                    "departure_date": formatDate(departureDate),
                                    "flight_id": model.flight_id
                                }
                                // 把当前选中的舱位传进去
                                data.seatClass = root.selectedClass
                                handleSelectFlight(data)
                            }
                        }
                    }
                }
            }
        }
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
                            // 选完城市后，重置搜索状态
                            resetSearchState()
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
