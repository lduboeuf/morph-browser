/**Workaround for https://github.com/ubports/morph-browser/issues/239 ( OTA-12 ) Until it is fixed in low level.
take a list of select options, pass it to a window.prompt so that it can be handled in QML with onJavascriptDialogRequested
**/
(function() {

    var generatedId = 0;

    function handleSelect(select) {

        var datas = { multiple: select.multiple };
        var opts = [];
        for (var i = 0; i < select.options.length; i++) {
            opts.push(select.options[i].innerText);
        }
        datas.options = opts;
        //Send a prompt so that WebEngine can intercept it with onJavascriptDialogRequested event
        var selectedItems = window.prompt("XX-MORPH-SELECT-OVERRIDE-XX", JSON.stringify(datas));
        console.log(selectedItems)
        if (selectedItems !== null)  {
            var sItems = JSON.parse(selectedItems);
            var j = 0;
            for( j; select.options.length; j++) {
                select.options[j].selected = (sItems.indexOf(j)>-1)
            }

           // select.options.forEach(option => select.options[selectedItem].selected = true);


            //fire the onchange event
            select.dispatchEvent(new Event('change', {bubbles: true}));
        }
    }

    //listen to mousedown events and see if it comes from a SELECT tag
    window.addEventListener('mousedown', function(evt) {
        var target = null;
        if (evt.target.tagName === 'SELECT') { //normal case
            target = evt.target;
        }else if (evt.composedPath()[0].tagName === 'SELECT') { // in case of event retargeting, original event is stored in composedPath array
            target = evt.composedPath()[0];
        }else if (evt.target.tagName === 'OPTION'){ //multiple select box case
            target = evt.target.closest('SELECT')
        }

        if (target !== null){
            //disable default opening of select drop box
            evt.preventDefault();
            handleSelect(target);
        }


    });

})();
