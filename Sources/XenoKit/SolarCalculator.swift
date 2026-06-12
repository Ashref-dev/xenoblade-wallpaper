import Foundation

/// Dependency-free solar position calculator (NOAA algorithm).
///
/// Computes the sun's elevation and azimuth for any latitude/longitude at any
/// instant from the system clock and explicit coordinates only. It never uses
/// CoreLocation / Location Services, so results are deterministic and pinned to
/// the chosen city rather than drifting to a system default.
public enum SolarCalculator {

    public struct Position: Sendable, Equatable {
        /// Degrees above the horizon. Negative = below (twilight / night).
        public let elevation: Double
        /// Degrees clockwise from true north (0 = N, 90 = E, 180 = S, 270 = W).
        public let azimuth: Double
        /// `true` before solar noon (sun climbing), `false` after (descending).
        public let isRising: Bool

        public init(elevation: Double, azimuth: Double, isRising: Bool) {
            self.elevation = elevation
            self.azimuth = azimuth
            self.isRising = isRising
        }
    }

    public static func position(date: Date = Date(),
                                latitude: Double,
                                longitude: Double) -> Position {
        let unix = date.timeIntervalSince1970
        let jd = unix / 86_400.0 + 2_440_587.5
        let t = (jd - 2_451_545.0) / 36_525.0

        let l0 = wrap360(280.46646 + t * (36_000.76983 + t * 0.0003032))
        let m = 357.52911 + t * (35_999.05029 - 0.0001537 * t)
        let mRad = deg2rad(m)

        let e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)

        let c = sin(mRad) * (1.914602 - t * (0.004817 + 0.000014 * t))
              + sin(2 * mRad) * (0.019993 - 0.000101 * t)
              + sin(3 * mRad) * 0.000289

        let trueLong = l0 + c
        let omega = 125.04 - 1_934.136 * t
        let lambda = trueLong - 0.00569 - 0.00478 * sin(deg2rad(omega))

        let seconds = 21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))
        let epsilon0 = 23.0 + (26.0 + seconds / 60.0) / 60.0
        let epsilon = epsilon0 + 0.00256 * cos(deg2rad(omega))
        let epsilonRad = deg2rad(epsilon)
        let lambdaRad = deg2rad(lambda)

        let declRad = asin(sin(epsilonRad) * sin(lambdaRad))

        let y = pow(tan(epsilonRad / 2.0), 2)
        let l0Rad = deg2rad(l0)
        let eot = 4.0 * rad2deg(
            y * sin(2 * l0Rad)
            - 2 * e * sin(mRad)
            + 4 * e * y * sin(mRad) * cos(2 * l0Rad)
            - 0.5 * y * y * sin(4 * l0Rad)
            - 1.25 * e * e * sin(2 * mRad)
        )

        let utcMinutes = ((jd + 0.5).truncatingRemainder(dividingBy: 1.0)) * 1_440.0

        var trueSolarTime = utcMinutes + eot + 4.0 * longitude
        trueSolarTime = trueSolarTime.truncatingRemainder(dividingBy: 1_440.0)
        if trueSolarTime < 0 { trueSolarTime += 1_440.0 }

        var hourAngle = trueSolarTime / 4.0 - 180.0
        if hourAngle < -180 { hourAngle += 360 }
        if hourAngle > 180 { hourAngle -= 360 }
        let hourAngleRad = deg2rad(hourAngle)

        let latRad = deg2rad(latitude)

        let cosZenith = sin(latRad) * sin(declRad)
                      + cos(latRad) * cos(declRad) * cos(hourAngleRad)
        let zenithRad = acos(clamp(cosZenith, -1.0, 1.0))
        let elevation = 90.0 - rad2deg(zenithRad)

        let azDenom = cos(latRad) * sin(zenithRad)
        var azimuth: Double
        if abs(azDenom) > 0.0001 {
            let azArg = clamp((sin(latRad) * cos(zenithRad) - sin(declRad)) / azDenom, -1.0, 1.0)
            let azRad = acos(azArg)
            if hourAngle > 0 {
                azimuth = wrap360(rad2deg(azRad) + 180.0)
            } else {
                azimuth = wrap360(540.0 - rad2deg(azRad))
            }
        } else {
            azimuth = latitude > declRad ? 180.0 : 0.0
        }

        return Position(elevation: elevation, azimuth: azimuth, isRising: hourAngle < 0)
    }

    private static func deg2rad(_ d: Double) -> Double { d * .pi / 180.0 }
    private static func rad2deg(_ r: Double) -> Double { r * 180.0 / .pi }
    private static func wrap360(_ d: Double) -> Double {
        var v = d.truncatingRemainder(dividingBy: 360.0)
        if v < 0 { v += 360.0 }
        return v
    }
    private static func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
        min(max(v, lo), hi)
    }
}
