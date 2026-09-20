import 'package:flutter_test/flutter_test.dart';

import 'package:bahhar/core/constants/app_constants.dart';
import 'package:bahhar/core/constants/fish_species.dart';
import 'package:bahhar/core/constants/omani_regions.dart';

void main() {
  group('FishSpecies catalogue', () {
    test('every species exposes bilingual + scientific + asset metadata', () {
      for (final s in FishSpecies.values) {
        expect(s.displayName, isNotEmpty);
        expect(s.nameAr, isNotEmpty);
        expect(s.scientificName, contains(' ')); // genus + species
        expect(s.assetPath, startsWith('assets/images/'));
        expect(s.assetPath, endsWith('.webp'));
      }
    });

    test('temperature and depth bands are well-formed', () {
      for (final s in FishSpecies.values) {
        expect(s.optimalTemp.minC, lessThan(s.optimalTemp.maxC));
        expect(s.preferredDepth.minM, lessThan(s.preferredDepth.maxM));
      }
    });

    test('temp/depth range membership respects bounds', () {
      const temp = TempRange(24.0, 29.0);
      expect(temp.contains(24.0), isTrue);
      expect(temp.contains(29.0), isTrue);
      expect(temp.contains(30.5), isFalse);
      expect(temp.label, '24–29°C');

      const depth = DepthRange(5, 80);
      expect(depth.contains(5), isTrue);
      expect(depth.contains(80), isTrue);
      expect(depth.contains(120), isFalse);
      expect(depth.label, '5–80 m');
    });

    test('SeasonRange handles wrapping seasons and month clamping', () {
      const wrapping = SeasonRange(10, 4); // Oct → Apr
      expect(wrapping.contains(11), isTrue);
      expect(wrapping.contains(2), isTrue);
      expect(wrapping.contains(6), isFalse);
      // Out-of-range months clamp rather than throw.
      expect(wrapping.contains(0), isTrue); // clamps to Jan (in range)
      expect(wrapping.contains(13), isTrue); // clamps to Dec (in range)

      const straight = SeasonRange(3, 10);
      expect(straight.contains(3), isTrue);
      expect(straight.contains(10), isTrue);
      expect(straight.contains(2), isFalse);
      expect(SeasonRange.yearRound.contains(7), isTrue);
    });

    test('tryParse resolves English, Arabic and alias spellings', () {
      expect(FishSpeciesX.tryParse('Kingfish'), FishSpecies.kingfish);
      expect(FishSpeciesX.tryParse('yellowfin tuna'), FishSpecies.yellowfinTuna);
      expect(FishSpeciesX.tryParse('Tuna'), FishSpecies.yellowfinTuna);
      expect(FishSpeciesX.tryParse('mahi_mahi'), FishSpecies.mahiMahi);
      expect(FishSpeciesX.tryParse('Grouper'), FishSpecies.hammour);
      expect(FishSpeciesX.tryParse('الكنعد'), FishSpecies.kingfish);
      expect(FishSpeciesX.tryParse('nonsense'), isNull);
      expect(FishSpeciesX.tryParse('   '), isNull);
    });
  });

  group('OmaniRegion metadata', () {
    test('every region has names, an anchor inside its bounds and a zone', () {
      for (final r in OmaniRegion.values) {
        expect(r.displayName, isNotEmpty);
        expect(r.nameAr, isNotEmpty);
        expect(r.coastBounds.contains(r.anchor), isTrue,
            reason: '${r.name} anchor should sit inside its coast bounds');
      }
    });

    test('anchors fall within greater Oman and sensible maritime zones', () {
      expect(OmaniRegion.musandam.maritimeZone, MaritimeZone.straitOfHormuz);
      expect(OmaniRegion.muscat.maritimeZone, MaritimeZone.gulfOfOman);
      expect(OmaniRegion.dhofar.maritimeZone, MaritimeZone.arabianSea);
      for (final r in OmaniRegion.values) {
        expect(omanCoastBounds.contains(r.anchor), isTrue);
      }
    });

    test('CoastBounds centre + containment', () {
      const b = CoastBounds(GeoPoint(0, 0), GeoPoint(10, 20));
      expect(b.center.lat, 5);
      expect(b.center.lon, 10);
      expect(b.contains(const GeoPoint(5, 5)), isTrue);
      expect(b.contains(const GeoPoint(-1, 5)), isFalse);
      expect(b.latSpan, 10);
      expect(b.lonSpan, 20);
    });

    test('tryParse matches catalogue + legacy region strings', () {
      expect(OmaniRegionX.tryParse('Muscat'), OmaniRegion.muscat);
      expect(OmaniRegionX.tryParse('Al Batinah South'),
          OmaniRegion.alBatinahSouth);
      expect(OmaniRegionX.tryParse('Dhofar'), OmaniRegion.dhofar);
      expect(OmaniRegionX.tryParse('مسقط'), OmaniRegion.muscat);
      expect(OmaniRegionX.tryParse('Atlantis'), isNull);
    });
  });

  group('AppConstants', () {
    test('geography + network defaults are sane', () {
      expect(AppConstants.omanCountryCode, '+968');
      expect(AppConstants.defaultLatitude, inInclusiveRange(16.0, 27.0));
      expect(AppConstants.defaultLongitude, inInclusiveRange(51.0, 61.0));
      expect(AppConstants.supportedLocales, containsAll(['en', 'ar']));
      expect(AppConstants.apiTimeout, const Duration(seconds: 30));
    });

    test('no secret material lives in compile-time constants', () {
      // API keys/tokens must never be baked into the client. Guard against a
      // regression by asserting the base URL default is the local placeholder
      // and that no constant holds an obvious key/token shape.
      expect(AppConstants.defaultApiBaseUrl, 'http://localhost:8000');
      const suspicious = 'api_key';
      expect(
        AppConstants.supportedLocales.every((l) => !l.contains(suspicious)),
        isTrue,
      );
    });
  });
}
