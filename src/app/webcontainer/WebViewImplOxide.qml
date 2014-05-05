/*
 * Copyright 2014 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtQuick.Window 2.0
import com.canonical.Oxide 1.0
import Ubuntu.Components 0.1
import Ubuntu.Components.Extras.Browser 0.2
import Ubuntu.UnityWebApps 0.1 as UnityWebApps
import Ubuntu.Components.Popups 0.1
import "../actions" as Actions
import ".."

WebViewImpl {
    id: webview

    property bool developerExtrasEnabled: false
    property var toolbar: null
    property string webappName: ""
    property var webappUrlPatterns: null

    currentWebview: webview

    contextualActions: ActionList {
        Actions.CopyLink {
            enabled: webview.contextualData.href.toString()
            onTriggered: Clipboard.push([webview.contextualData.href])
        }
        Actions.CopyImage {
            enabled: webview.contextualData.img.toString()
            onTriggered: Clipboard.push([webview.contextualData.img])
        }
    }

    function shouldOpenPopupsInDefaultBrowser() {
        return formFactor !== "desktop";
    }

    function isRunningAsANamedWebapp() {
        return webview.webappName && typeof(webview.webappName) === 'string' && webview.webappName.length != 0
    }

    function haveValidUrlPatterns() {
        return webappUrlPatterns && webappUrlPatterns.length !== 0
    }

    function isNewForegroundWebViewDisposition(disposition) {
        return disposition === NavigationRequest.DispositionNewPopup ||
               disposition === NavigationRequest.DispositionNewForegroundTab;
    }

    function shouldAllowNavigationTo(url) {
        // The list of url patterns defined by the webapp takes precedence over command line
        if (isRunningAsANamedWebapp()) {
            if (unityWebapps.model.exists(unityWebapps.name) &&
                unityWebapps.model.doesUrlMatchesWebapp(unityWebapps.name, url)) {
                return true;
            }
        }

        // We still take the possible additional patterns specified in the command line
        // (the in the case of finer grained ones specifically for the container and not
        // as an 'install source' for the webapp).
        if (webappUrlPatterns && webappUrlPatterns.length !== 0) {
            for (var i = 0; i < webappUrlPatterns.length; ++i) {
                var pattern = webappUrlPatterns[i]
                if (url.match(pattern)) {
                    return true;
                }
            }
        }

        return false;
    }

    function navigationRequestedDelegate(request) {
        var newForegroundPageRequest = isNewForegroundWebViewDisposition(request.disposition)
        var url = request.url.toString()

        // Covers some edge cases corresponding to the default window.open() behavior.
        // When it is being called, the targetted URL will not load right away but
        // will first round trip to an "about:blank".
        // See https://developer.mozilla.org/en-US/docs/Web/API/Window.open
        if (newForegroundPageRequest && url == 'about:blank') {
            console.log('Accepting a new window request to navigate to "about:blank"')
            request.action = NavigationRequest.ActionAccept
            return;
        }

        if (newForegroundPageRequest && shouldOpenPopupsInDefaultBrowser()) {
            console.debug('Opening: popup window ' + url + ' in the browser window.')

            request.action = NavigationRequest.ActionReject
            Qt.openUrlExternally(url);
            return;
        }

        // Pass-through if we are not running as a named webapp (--webapp='Gmail')
        // or if we dont have a list of url patterns specified to filter the
        // browsing actions
        if ( ! webview.haveValidUrlPatterns() && ! webview.isRunningAsANamedWebapp()) {
            request.action = NavigationRequest.ActionAccept
            return
        }

        request.action = NavigationRequest.ActionReject
        if (webview.shouldAllowNavigationTo(url))
            request.action = NavigationRequest.ActionAccept

        // SAML requests are used for instance by Google Apps for your domain;
        // they are implemented as a HTTP redirect to a URL containing the
        // query parameter called "SAMLRequest".
        // Besides letting the request through, we must also add the SAML
        // domain to the list of the allowed hosts.
        if (request.disposition === NavigationRequest.DispositionCurrentTab &&
            url.indexOf("SAMLRequest") > 0) {
            var urlRegExp = new RegExp("https?://([^?/]+)")
            var match = urlRegExp.exec(url)
            var host = match[1]
            var escapeDotsRegExp = new RegExp("\\.", "g")
            var hostPattern = "https?://" + host.replace(escapeDotsRegExp, "\\.") + "/"
            console.log("SAML request detected. Adding host pattern: " + hostPattern)
            webappUrlPatterns.push(hostPattern)
            request.action = NavigationRequest.ActionAccept
        }

        if (request.action === NavigationRequest.ActionReject) {
            console.debug('Opening: ' + url + ' in the browser window.')
            Qt.openUrlExternally(url)
        }
    }

    function createPopupWindow(request) {
        popupWebViewFactory.createObject(webview, { request: request, width: 500, height: 800 });
    }

    Component {
        id: popupWebViewFactory
        Window {
            id: popup
            property alias request: popupBrowser.request
            UbuntuWebView {
                id: popupBrowser
                anchors.fill: parent

                function navigationRequestedDelegate(request) {
                    var url = request.url.toString()

                    // If we are to browse in the popup to a place where we are not allows
                    if ( ! isNewForegroundWebViewDisposition(request.disposition) &&
                            ! webview.shouldAllowNavigationTo(url)) {
                        request.action = NavigationRequest.ActionReject
                        Qt.openUrlExternally(url);
                        popup.close()
                        return;
                    }

                    // Fallback to regulat checks (there is a bit of overlap)
                    webview.navigationRequestedDelegate(request)
                }

                onNewViewRequested: webview.createPopupWindow(request)

                // Oxide (and Chromium) does not inform of non user
                // driven navigations (or more specifically redirects that
                // would be part of an popup/webview load (after its been
                // granted). Quite a few sites (e.g. Youtube),
                // create popups when clicking on links (or following a window.open())
                // with proper youtube.com address but w/ redirection
                // params, e.g.:
                // http://www.youtube.com/redirect?q=http%3A%2F%2Fgodzillamovie.com%2F&redir_token=b8WPI1pq9FHXeHm2bN3KVLAJSfp8MTM5NzI2NDg3NEAxMzk3MTc4NDc0
                // In this instance the popup & navigation is granted, but then
                // a redirect happens inside the popup to the real target url (here http://godzillamovie.com)
                // which is not trapped by a navigation requested and therefore not filtered.
                // The only way to do it atm is to listen to url changed in popups & also
                // filter there.
                onUrlChanged: {
                    var _url = url.toString();
                    if (_url.trim().length === 0)
                        return;

                    if (_url != 'about:blank' && ! webview.shouldAllowNavigationTo(_url)) {
                        Qt.openUrlExternally(_url);
                        popup.close()
                    }
                }
            }
            Component.onCompleted: popup.show()
        }
    }

    onNewViewRequested: createPopupWindow(request)

    preferences.localStorageEnabled: true

    // Small shim needed when running as a webapp to wire-up connections
    // with the webview (message received, etc…).
    // This is being called (and expected) internally by the webapps
    // component as a way to bind to a webview lookalike without
    // reaching out directly to its internals (see it as an interface).
    function getUnityWebappsProxies() {
        var eventHandlers = {
            onAppRaised: function () {
                if (webbrowserWindow) {
                    try {
                        webbrowserWindow.raise();
                    } catch (e) {
                        console.debug('Error while raising: ' + e);
                    }
                }
            }
        };
        return UnityWebAppsUtils.makeProxiesForWebViewBindee(webview, eventHandlers)
    }
}