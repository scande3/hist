function histInstantiateHistory(aceMode, heightMode, left_content, right_content) {
    var histDiffer = new AceDiff({
        element: '#histAceDiff',
        diffGranularity: 'specific',
        maxDiffs: Infinity,
        mode: aceMode,
        left: {
            content: left_content,
            editable: false
        },
        right: {
            content: right_content,
            editable: false
        }
    });

    if(heightMode == 'all' || heightMode == 'max_length') {
        histDiffer.getEditors().left.setOption("maxLines", Infinity);
        histDiffer.getEditors().right.setOption("maxLines", Infinity);
    }

    if(aceMode == "ace/mode/html") {
        histDiffer.getEditors().left.setOption("wrap", true);
        histDiffer.getEditors().right.setOption("wrap", true);
    }

    setInterval(function(){ histAdjustDivHeight(histDiffer, heightMode); }, 200);
}

// Word wrap throwing line counts off...
function histAdjustDivHeight(histDiffer, heightMode) {
    //console.log('Screen length try: ' + histDiffer.getEditors().left.getSession().getScreenLength());
    //console.log('Screen height try: ' + ($(window).height() - 180));
    if(heightMode == 'screen') {
        screenHeight = $(window).height() - 180;
        if ($("#histAceDiff").height() != screenHeight) {
            $("#histAceDiff").height(screenHeight);

            var lineHeight = histDiffer.getEditors().left.renderer.lineHeight;
            var lines = Math.floor(screenHeight / lineHeight);
            //histDiffer.getEditors().left.setOption("maxLines", lines);
            //histDiffer.getEditors().right.setOption("maxLines", lines);

            histDiffer.getEditors().left.resize();
            histDiffer.getEditors().right.resize();
        }
    } else if(heightMode == 'all') {
        screenHeight = $(window).height() - 180;
        if ($("#histAceDiff").height() != screenHeight) {
            $("#histAceDiff").height(screenHeight);
        }
    } else if(heightMode == 'max_length') {
        var height = 0;
        if(document.getElementsByClassName("acediff__left")[0].offsetHeight > height) {
            height = document.getElementsByClassName("acediff__left")[0].offsetHeight;
        }
        if(document.getElementsByClassName("acediff__right")[0].offsetHeight > height) {
            height = document.getElementsByClassName("acediff__right")[0].offsetHeight;
        }
        if($("#histAceDiff").height() != height) {
            $("#histAceDiff").height(height);
        }
    }
}
