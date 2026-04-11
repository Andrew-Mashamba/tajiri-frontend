# Qibla (Qibla Compass) — Feature Description

## Tanzania Context

"Qibla" is the direction of the Kaaba in Makkah, Saudi Arabia, which Muslims face during prayer. For Tanzanian Muslims, the Qibla direction is roughly north-northeast (approximately 2-15 degrees from north, depending on location within Tanzania). Knowing the exact Qibla direction is essential for the validity of daily prayers.

In urban areas, many homes and mosques have the Qibla direction permanently marked. However, when traveling, visiting new places, or praying outdoors, Muslims need to determine the Qibla direction. Traditional methods include using the sun's position or asking locals. Younger Tanzanians increasingly rely on phone compasses, but many existing apps require internet connectivity or have poor calibration on budget Android devices (which dominate the Tanzanian market). A reliable offline Qibla compass with clear visual feedback is highly valued.

## International Reference Apps

1. **Qibla Finder (Google)** — Web-based AR Qibla finder using phone camera
2. **Muslim Pro** — Integrated Qibla compass within prayer times app
3. **Qibla Connect** — Dedicated Qibla compass with AR overlay
4. **Qibla Compass (SimpleApps)** — Minimalist compass with accuracy indicator
5. **Athan (IslamicFinder)** — Qibla compass with map view showing line to Makkah

## Feature List

1. Digital compass — compass needle pointing to Qibla direction from current location
2. Accuracy indicator — visual feedback on compass calibration quality (green/yellow/red)
3. Calibration guide — step-by-step instructions to calibrate phone magnetometer
4. AR overlay option — camera view with Qibla direction arrow overlaid (augmented reality)
5. Map view — satellite map showing straight line from current location to Kaaba
6. Distance to Makkah — display distance in kilometers from current location
7. Degree display — exact bearing angle to Qibla in degrees
8. Offline functionality — works entirely offline using GPS and magnetic sensor
9. Lock direction — freeze compass at Qibla direction for placing prayer mat
10. Vibration feedback — phone vibrates when pointing at exact Qibla direction
11. Location manual entry — enter location manually if GPS is unavailable
12. Magnetic declination — automatic compensation for magnetic vs. true north
13. Multiple calculation methods — great circle (most accurate) and rhumb line options
14. Night mode — dark theme for low-light environments
15. Sound notification — audio tone when aligned with Qibla

## Key Screens

- **Compass Screen** — large compass display with Qibla needle, accuracy indicator, degree readout
- **AR View** — camera feed with Qibla direction arrow and distance overlay
- **Map View** — map showing current position, Kaaba position, and connecting great circle line
- **Calibration Screen** — animated instructions for figure-8 calibration motion
- **Settings** — calculation method, vibration toggle, sound toggle, manual location entry

## TAJIRI Integration Points

- **LocationService.getRegions(), getDistricts()** — GPS-based Qibla direction calculation; auto-recalculate when location changes; manual location entry fallback
- **ProfileService.getProfile()** — Qibla tool available to all users with Islamic faith profile; accessible from faith dashboard
- **Cross-module: Wakati wa Sala** — mini Qibla compass widget accessible from prayer times screen; quick-access before each prayer
- **Cross-module: Tafuta Msikiti** — Qibla direction shown relative to nearest mosque locations via LocationService
- **Cross-module: Ramadan** — quick Qibla access during Taraweeh and additional Ramadan prayers
- **Cross-module: travel/ module** — Qibla recalculates automatically when traveling to new locations within Tanzania
- **Offline Support** — full offline capability using GPS and magnetic sensor; critical for rural Tanzania with limited connectivity
