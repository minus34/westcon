var map;
var info;
var legend;
var json;
var geojsonLayer;
var currTarget;
var startZoom = 10;

var currStat = "o_91";
var currId = 11703;
var currName = "Sydney Inner City";
var currValue = 63498;

var themeGrades = [0, 2500, 5000, 10000, 20000, 40000];


function init() {
    //Initialize the map on the "map" div
    map = new L.Map('map');
    
    //Control that shows state info on hover
    info = L.control();

    info.onAdd = function (map) {
        this._div = L.DomUtil.create('div', 'info');
        this.update();
        return this._div;
    };

    info.update = function (props) {
        this._div.innerHTML = (props ? '<h4>' + props.name +
            '</h4><b>' + parseInt(props.d).toLocaleString() + ' </b> motorists drive to here for work<br/>'
            : 'Select an area of Sydney');
    };

    info.addTo(map);
    
    //Create a legend control
    legend = L.control({ position: 'bottomright' });

    legend.onAdd = function (map) {

        var div = L.DomUtil.create('div', 'info legend'),
            grades = themeGrades,
            labels = [],
            from, to;

        for (var i = 0; i < grades.length; i++) {
            from = grades[i];
            to = grades[i + 1];

            labels.push(
                '<i style="background:' + getColor(from + 1) + '"></i> ' +
                from + (to ? '&ndash;' + to : '+'));
        }

        div.innerHTML = "<h4>Motorists<br/>commuting<br/>to " + currName + "</h4>" +
                        "<div id='mapLegend'>" + labels.join('<br/>') + '</div>';

        return div;
    };
    
    legend.addTo(map);

    // // add MapBox tiles
    // var tiles = L.tileLayer('http://{s}.tiles.mapbox.com/v3/{id}/{z}/{x}/{y}.png', {
      // attribution: '<a href="https://www.mapbox.com/about/maps/">MapBox Terms &amp; Feedback</a>',
      // id: 'examples.map-20v6611k'
    // }).addTo(map);
    
    //Add tiles
		// var tiles = L.tileLayer('http://a.tile.stamen.com/toner/{z}/{x}/{y}.png', { 
			// attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a> &mdash; Map data: &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors,<a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>'
    // }).addTo(map);
    
    var tiles = L.tileLayer('http://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',{
      attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="http://cartodb.com/attributions">CartoDB</a>'
    }).addTo(map);
    
    //Change the start zoom and font size based on window size
    var windowWidth = $(window).width();
    var windowHeight = $(window).height();
    var width = 0

    if (windowWidth > windowHeight) width = windowWidth;
    else width = windowHeight;

    if (width > 2000) {
        startZoom += 1;
        $('.info').css({ 'font': 'normal normal normal 16px/22px Arial, Helvetica, sans-serif', 'line-height': '22px' });
        $('.legend').css({ 'font': 'normal normal normal 16px/22px Arial, Helvetica, sans-serif', 'line-height': '22px' });
        $('.dropdown').css({ 'line-height': '22px' });
    }
    else if (width < 1200) {
        $('.info').css({ 'font': 'normal normal normal 12px/16px Arial, Helvetica, sans-serif', 'line-height': '18px' });
        $('.legend').css({ 'font': 'normal normal normal 12px/16px Arial, Helvetica, sans-serif', 'line-height': '18px' });
        $('.dropdown').css({ 'line-height': '18px' });
    }

    //Set the view to a given centre and zoom
    map.setView(new L.LatLng(-33.85, 151.15), startZoom);

    //Acknowledge the data providers
    map.attributionControl.addAttribution('<br/>Data © <a href="http://www.bts.nsw.gov.au/">NSW Bureau of Transport Statistics</a>, <a href="http://www.abs.gov.au/">Australian Bureau Statistics</a>');

    //Load the boundaries
    json = (function () {
        var json = null;
        $.ajax({
            'async': false,
            'global': false,
            'url': "sa3.json",
            'dataType': "json",
            'success': function (data) {
                json = data;
            }
        });
        return json;
    })();
    
    //Display the boundaries
    loadGeoJson(json);
}


function loadGeoJson(json) {
    if (json != null) {
        try {
            geojsonLayer.clearLayers();
        }
        catch (err) {
            //dummy
        }

        geojsonLayer = L.geoJson(json, {
            style: style,
            onEachFeature: onEachFeature
        }).addTo(map);
        //}).bindLabel('%', {noHide: true, direction: 'auto'}).addTo(map);
        
        //geojsonLayer.showLabel();
        
        //Show percentage labels
        // map.eachLayer(function (layer) {
          // try {
            // layer.showLabel();
          // }
          // catch (err) {
            // //dummy
          // }
        // });
    }
}


//Sets style on each GeoJSON object
function style(feature) {
    //colVal = parseFloat(feature.properties[currStat]);
    colVal = parseFloat(feature.properties.d);
    
    if (currStat == "o_" + feature.properties.id) {
      return {
          weight: 5,
          opacity: 0.8,
          color: "#333",
          fillOpacity: 0.7,
          fillColor: getColor(colVal)
      };
    } else {
      return {
          weight: 1,
          opacity: 0.8,
          color: getColor(colVal),
          fillOpacity: 0.7,
          fillColor: getColor(colVal)      
      };
    }
}


//Get colour depending on value
function getColor(d) {
    return d > themeGrades[5] ? '#d73027' :
           d > themeGrades[4] ? '#fc8d59' :
           d > themeGrades[3] ? '#fee08b' :
           d > themeGrades[2] ? '#d9ef8b' :
           d > themeGrades[1] ? '#91cf60' :
                                '#1a9850';
}


function onEachFeature(feature, layer) {
  
  //var xy = new L.LatLng(feature.properties.y, feature.properties.x)
  // var theValue = feature.properties[currStat];
  // var percent = parseInt(100 * parseFloat(theValue) / parseFloat(currValue))
  // var percentText

  // if (percent == 0) {
    // percentText = "<1%";
  // } else {
    // percentText = percent.toString() + "%"    
  // }

  // layer.bindLabel(percentText, {
    // noHide: false,
    // offset: [0,0],
    // opacity: 0.85,
    // direction: 'auto'
  // });
  
  //layer.showLabel();

  //console.log(feature.properties.name + ' : ' + theValue + ' : ' + percent + '%')
  
  // var label = new L.Label();

  // label.setContent(percentText);
  // //label.setOffset([0,0]);
  // label.setOpacity(0.85);
  // label.setLatLng(xy);
  // map.showLabel(label);
  
  layer.on({
      mouseover: highlightFeature,
      mouseout: resetHighlight,
      click: function (e) {
          if (currTarget) {
              resetHighlight(currTarget); //reset previously clicked electorate
          }
          changeTheme(e);
          //selectedFeature(e);
          currTarget = e;
      }
  });
}


//Change map theme when user clicks on electorate
function changeTheme(e) {
  var layer = e.target;

  currStat = "o_" + layer.feature.properties.id;
  currName = layer.feature.properties.name;
  currValue = parseInt(layer.feature.properties.d);
  
  //Display the boundaries
  loadGeoJson(json);

  // //Update the legend
  // labels = []

  // for (var i = 0; i < themeGrades.length; i++) {
      // from = themeGrades[i];
      // to = themeGrades[i + 1];

      // labels.push(
          // '<i style="background:' + getColor(from + 1) + '"></i> ' +
          // from + (to ? '&ndash;' + to : '+'));
  // }

  // var data = labels.join('<br/>');
  
  // $("#mapLegend").hide().html(data).fadeIn('fast');

  info.update(layer.feature.properties);
};


// function selectedFeature(e) {
    // var layer = e.target;

    // layer.setStyle({
        // weight: 5,
        // color: '#0000AA',
        // fillOpacity: 0.65
    // });

    // if (!L.Browser.ie && !L.Browser.opera) {
        // layer.bringToFront();
    // }

    // info.update(layer.feature.properties);

// }

function highlightFeature(e) {
    var layer = e.target;

    highlightStat = "o_" + layer.feature.properties.id;
    
    if (currStat != highlightStat) {
      layer.setStyle({
          weight: 5,
          color: '#666',
          fillOpacity: 0.65
      });

      if (!L.Browser.ie && !L.Browser.opera) {
          layer.bringToFront();
      }
    }
    
    info.update(layer.feature.properties);

}


function resetHighlight(e) {
    geojsonLayer.resetStyle(e.target);
    info.update();
}
