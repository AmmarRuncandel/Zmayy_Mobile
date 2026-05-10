// Map tile URLs taken from `MapViewInner.tsx` (Leaflet Carto Dark Matter).

abstract final class MapTiles {
  static const cartoDarkMatterTemplate =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  /// OSM + CARTO attribution string from React `ATTRIB`.
  static const attribution =
      '&copy; OpenStreetMap contributors &copy; CARTO';
}
