var map;
var info;
var info2;
var legend;
var json;
var geojsonLayer;
var startZoom = 10;
var currTarget;
var currId;

//var currId = 11703;
//var currName = "Sydney Inner City";
//var currValue = 107768;

var themeGrades = [0, 250, 500, 1000, 2000, 4000, 8000];

function init() {
  //Initialize the map on the "map" div
  map = new L.Map('map');
  
  //Control that shows info on the selected trip destination
  info = L.control();

  info.onAdd = function (map) {
    this._div = L.DomUtil.create('div', 'info');
    this.update();
    return this._div;
  };

  info.update = function (props) {
    this._div.innerHTML = (props ? '<b>' + parseInt(props.d_motorists).toLocaleString() + ' </b> motorists drive to <b>' + props.name + '</b> for work'
      : 'Click/tap on an area of Sydney');
  };

  info.addTo(map);

  //Control that shows info on the trip origin
  info2 = L.control();

  info2.onAdd = function (map) {
    this._div = L.DomUtil.create('div', 'info');
    this.update();
    return this._div;
  };

  info2.update = function (name, stat) {
    this._div.innerHTML = (name ? '<b>' + stat.toLocaleString() + ' </b> drive from <b>' + name + '</b>'
      : '');
  };

  info2.addTo(map);
  
  //Create a legend control
  legend = L.control({ position: 'bottomright' });

  legend.onAdd = function(map){
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

    div.innerHTML = "<h4>Motorists</h4>" + "<div id='mapLegend'>" + labels.join('<br/>') + '</div>';

    return div;
  };
  
  legend.addTo(map);
  
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
  
  //Display the bdys
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
    
    if (currId) {
      geojsonLayer = L.geoJson(json, {
        style: style,
        onEachFeature: onEachFeature
      }).addTo(map);
      
      currTarget = geojsonLayer.getLayer(currId);
      
      console.log(currTarget);
      
    } else {
      geojsonLayer = L.geoJson(json, {
        //style: style,
        style: {
          weight: 1,
          opacity: 0.0,
          color: '#0000ff',
          fillOpacity: 0.3,
          fillColor: '#0000ff'
        },
        onEachFeature: onEachFeature
      }).addTo(map);
    }
  }
}

//Sets style on each GeoJSON object
function style(feature) {
  
  colVal = parseFloat(feature.properties["o_" + currId]);
  
  return {
    weight: 1,
    opacity: 0.8,
    color: getColor(colVal),
    fillOpacity: 0.7,
    fillColor: getColor(colVal)      
  };
}

//Get colour depending on value
function getColor(d) {

  return d > themeGrades[6] ? '#551A8B' :
         d > themeGrades[5] ? '#d73027' :
         d > themeGrades[4] ? '#fc8d59' :
         d > themeGrades[3] ? '#fee08b' :
         d > themeGrades[2] ? '#d9ef8b' :
         d > themeGrades[1] ? '#91cf60' :
                              '#1a9850';
}

function onEachFeature(feature, layer) {
  
  // var xy = new L.LatLng(feature.properties.y, feature.properties.x)
  // var theValue = feature.properties["o_" + currId];
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
      //changeTheme(e);
      selectedFeature(e);
      currTarget = e;
    }
  });
}

// //Change map theme when user clicks on destination
// function changeTheme(e) {
  // var layer = e.target;

  // currId = layer.feature.properties.id;
  // //currName = layer.feature.properties.name;
  // //currValue = parseInt(layer.feature.properties.d_motorists);
  
  // //Display the boundaries
  // loadGeoJson(json);

  // info.update(layer.feature.properties);
// };

function selectedFeature(e) {
  var layer = e.target;

  layer.setStyle({
      weight: 5,
      color: '#aaaaaa'
  });

  currId = layer.feature.properties.id;
  currTarget = undefined; //need to reset this as it doesn't exist after bdys are reloaded
    
  //Refresh the boundaries with the new colours
  loadGeoJson(json);
  
  // //Doesn't work
  // for (lyr of geojsonLayer.getLayers()) {
    // lyr.setStyle(style);  
  // }
    
  if (!L.Browser.ie && !L.Browser.opera) {
      layer.bringToFront();
  }

  info.update(layer.feature.properties);
}

function highlightFeature(e) {
  var layer = e.target;

  highlightedId = layer.feature.properties.id;
  
  if (currId != highlightedId) {
    layer.setStyle({
      weight: 3,
      opacity: 0.8,
      color: '#0000ff'
    });

    if (!L.Browser.ie && !L.Browser.opera) {
      layer.bringToFront();

      if(currTarget) {
        currTarget.target.bringToFront();
      }
    }
  }
  
  if (currTarget) {
    var stat = currTarget.target.feature.properties["o_" + highlightedId];
    var name = layer.feature.properties.name;
    info2.update(name, stat);
  }
}


function resetHighlight(e) {
  var layer = e.target;

  highlightedId = layer.feature.properties.id;
  
  if (currId != highlightedId) {
    geojsonLayer.resetStyle(e.target);
  }
  
  info2.update();
}
