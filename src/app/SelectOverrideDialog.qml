/*
 * Copyright 2013-2016 Canonical Ltd.
 *
 * This file is part of morph-browser.
 *
 * morph-browser is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * morph-browser is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.7
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import Ubuntu.Components.Popups 1.3 as Popups

Popups.Dialog {
    id: selectOverlay
    objectName: "selectOverrideDialog"
    modal: true

    __closeOnDismissAreaPress: true
    __dimBackground: false //avoid default opaque background

    property string data: ""
    property var object: data.length > 0 ? JSON.parse(data) :  { multiple: false, options: []}
    property var selectOptions: object.options
    property bool isMultipleSelect: object.multiple
    property var selection: []
    
    signal accept(string text)
    signal reject()

    onAccept: hide()
    onReject: hide()



    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: units.gu(3)


        ListItem.ItemSelector {
            model: selectOverlay.selectOptions
            expanded: true
            multiSelection: isMultipleSelect
            //selectedIndex: -1
            showDivider: true
            //containerHeight: itemHeight * 4
            delegate: OptionSelectorDelegate {
                text: modelData
                selected: selection.indexOf(index) > -1
            }
            onDelegateClicked: {

                if (!isMultipleSelect) {
                    selection.push(index)
                    accept(JSON.stringify(selection))
                }else{

                    var idx = selection.indexOf(index);
                    if (idx === -1){
                        console.log("add index", index)
                        selection.push(index);
                    }else{
                        console.log("remove index", index)
                        selection.splice(idx, 1);
                    }
                    console.log(selection)

                }

            }
            Component.onCompleted : selectedIndex = -1

            //        Label {
            //            anchors {
            //                left: parent.left
            //                leftMargin: units.gu(2)
            //                right: checkbox.left
            //                rightMargin: units.gu(2)
            //                verticalCenter: parent.verticalCenter
            //            }
            //            text: modelData
            //        }

            //        CheckBox {
            //            id: checkbox
            //            visible: isMultipleSelect
            //            checked: selection.indexOf(index) > -1
            //            anchors {
            //                verticalCenter: parent.verticalCenter
            //                right: parent.right
            //            }

            //}


            //onTriggered: handleSelection(index, checkbox.checked)
        }




        Row{
            anchors.horizontalCenter: parent.horizontalCenter
            visible: isMultipleSelect
            spacing: units.gu(3)
            //width: parent.width
            Button {
                anchors.margins: units.gu(2)
                text: i18n.tr("OK")
                color: theme.palette.normal.positive
                objectName: "okButton"
                onClicked: accept(JSON.stringify(selectOverlay.selection))
            }

            Button {
                anchors.margins: units.gu(2)
                objectName: "cancelButton"
                text: i18n.tr("Cancel")
                onClicked: reject()
            }
        }

    }

    //make sure to send signal when Popup close
    Connections {
        target: __eventGrabber
        onPressed: {
            reject()

        }
    }





}
