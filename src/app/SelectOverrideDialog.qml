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
import QtQuick.Layouts 1.1
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

    function handleSelection(selectIndex) {
        if (!isMultipleSelect) {
            selection.push(selectIndex)
            accept(JSON.stringify(selection))
        }else{

            var idx = selection.indexOf(selectIndex);
            if (idx === -1){
                selection.push(selectIndex);
            }else{
                selection.splice(idx, 1);
            }
            console.log(selection)
        }
    }


    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: units.gu(2)

        Repeater {
            id: listView

            model: selectOverlay.selectOptions
            //contentHeight: contentItem.childrenRect.height
            delegate:  ListItem.Standard  {
                id: item
                text: modelData
                width: parent.width
                highlightWhenPressed: false
                showDivider: true
                height: units.gu(5)

                control: CheckBox {
                    visible: isMultipleSelect
                    checked: item.selected
                    //checked:selection.indexOf(index) > -1
                }

                onClicked: {
                    if (!isMultipleSelect) {
                        selection.push(index)
                        accept(JSON.stringify(selection))
                    }else{

                        var idx = selection.indexOf(index);
                        if (idx === -1){
                            selection.push(index);
                            selected = true
                        }else{
                            selection.splice(idx, 1);
                            selected = false
                        }

                        console.log(selection)
                    }
                }
            }
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
