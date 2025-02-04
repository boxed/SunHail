import SwiftUI
import CoreLocation
import Combine

private let sun_ray_density = 0.6
private let star_density = 0.3
private let rain_density = 0.5
private let fog_density = 1.27
private let circle_inner_diameter = 3.7
private let cloud_ray_density = 0.20
private let cloud_diameter = 3.0
private let cloud_diameter2 = 2.98
private let cloud_wiggle_size = 1.02
private let bolt_diameter = 3.1
private let bolt_diameter2 = 3.7

let dark_cloud_color = Color(#colorLiteral(red: 0.3568909366, green: 0.3843440824, blue: 0.4227784864, alpha: 1))
let dark_cloud_border_offset = 0.05

let snow_color = Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
let lightning_color = Color(#colorLiteral(red: 0.9607843161, green: 0.908961656, blue: 0.6438163823, alpha: 1))
let fog_color = Color(#colorLiteral(red: 0.579559949, green: 0.579559949, blue: 0.579559949, alpha: 0.7122568295))

let cold = #colorLiteral(red: 0.308781036, green: 0.6557458493, blue: 1, alpha: 1)
let coldish = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
let hot = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
let warm = #colorLiteral(red: 0.9372549057, green: 0.7610096826, blue: 0.4300234694, alpha: 1)
let warmer = #colorLiteral(red: 0.9372549057, green: 0.5117781247, blue: 0.1694676863, alpha: 1)
let nice = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)


let generator = RandomNumberGeneratorWithSeed(seed: 8927686396)
let star_field_random_numbers = (0...500).map {_ in Double(generator.next()) / Double(UInt64.max)}
let star_field_random_numbers2 = (0...500).map {_ in Double(generator.next()) / Double(UInt64.max)}


func clockPathInner(path: inout Path, bounds: CGRect, progress: TimeInterval, extraSize: CGFloat = 1) {
    let pi = Double.pi
    let position: Double
    position = pi - (2*pi * progress)
    let size = bounds.height / 2
    let x = bounds.midX + CGFloat(sin(position)) * size * extraSize
    let y = bounds.midY + CGFloat(cos(position)) * size * extraSize
    path.move(
        to: CGPoint(
            x: bounds.midX,
            y: bounds.midY
        )
    )
    path.addLine(to: CGPoint(x: x, y: y))
}

func clockPath(now: Date, bounds: CGRect, progress: Double, extraSize: CGFloat) -> Path {
    Path { path in
        clockPathInner(path: &path, bounds: bounds, progress: progress, extraSize: extraSize)
    }
}

struct ClockDial: Shape {
    var now: Date;
    var progress: Double
    var extraSize: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let now: Date = Date();
        return clockPath(now: now, bounds: rect, progress: progress, extraSize: extraSize)
    }
}

extension BinaryInteger {
    var degreesToRadians: CGFloat { CGFloat(self) * .pi / 180 }
}

extension FloatingPoint {
    var degreesToRadians: Self { self * .pi / 180 }
    var radiansToDegrees: Self { self * 180 / .pi }
}


let wiggle_c_set: Set = [
    1, 3, 6, 7,
]


struct Rays: Shape {
    let a: CGFloat
    let b: CGFloat
    let ray_density: Double
    var wiggle_a: Bool = false
    var wiggle_b: Bool = false
    var wiggle_c: Bool = false
    var start_degree = 0.0
    var end_degree = 360.0
    var wiggle_size = 1.01
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let degrees = end_degree - start_degree

        let number_of_rays = Int(Double(degrees) * ray_density)
        
        if number_of_rays < 0 {
            return p
        }
        
        for i in 0..<number_of_rays {
            let degree = start_degree + CGFloat(i) / ray_density
            var size_a : CGFloat = rect.height/a
            var size_b : CGFloat = rect.height/b
            if wiggle_a && i % 2 == 0 {
                size_a *= wiggle_size
            }
            if wiggle_b && i % 2 == 1 {
                size_b *= wiggle_size
            }
            if wiggle_c && wiggle_c_set.contains(i) {
                size_b *= wiggle_size
            }
            let radians = .pi - degree.degreesToRadians
            let x = sin(radians) * size_a + rect.width / 2
            let y = cos(radians) * size_a + rect.height / 2
            let x2 = sin(radians) * size_b + rect.width / 2
            let y2 = cos(radians) * size_b + rect.height / 2
            p.move(to: CGPoint(x: x, y: y))
            p.addLine(to: CGPoint(x: x2, y: y2))
        }
        return p
    }
}

struct StarRays: Shape {
    let ray_density: Double
    var start_degree = 0.0
    var end_degree = 360.0
    
    func path(in rect: CGRect) -> Path {
        let a = 2.5
        let b = 3.5

        var p = Path()
        let degrees = end_degree - start_degree

        let number_of_rays = Int(Double(degrees) * ray_density)
        
        if number_of_rays < 0 {
            return p
        }
        
        for i in 0..<number_of_rays {
            let degree = start_degree + CGFloat(i) / ray_density
            let size_a : CGFloat = rect.height/a
            let size_b : CGFloat = rect.height/b
            
            let radians = .pi - degree.degreesToRadians
            let x = sin(radians) * size_a + rect.width / 2
            let y = cos(radians) * size_a + rect.height / 2
            let x2 = sin(radians) * size_b + rect.width / 2
            let y2 = cos(radians) * size_b + rect.height / 2
            
            let r = star_field_random_numbers[i]
            let s = star_field_random_numbers2[i]
            assert(r >= 0 && r <= 1.0)
            
            let sx = x2 + (x - x2) * r
            let sy = y2 + (y - y2) * r

//            p.move(to: CGPoint(x: x, y: y))
//            p.addLine(to: CGPoint(x: x2, y: y2))

            addStar(p: &p, s: 70.0 * s, x: sx, y: sy)
            
//            p.addLine(to: CGPoint(x: x2, y: y2))
        }
        return p
    }
}

struct Bolt: Shape {
    let a: CGFloat
    let b: CGFloat
    var start_degree = 0.0
    var end_degree = 360.0
    
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let degree = (start_degree + end_degree) / 2
    
        let size_a : CGFloat = rect.height/a
        let size_b : CGFloat = rect.height/b
        let size_m = (size_a + size_b)/2
        let radians: CGFloat = .pi - degree.degreesToRadians
        for i in [-0.21, -0.14, -0.07, 0.0, 0.07, 0.14, 0.21] {
            p.move(
                to: CGPoint(
                    x: sin(i + radians + 0.03) * size_a + rect.width / 2,
                    y: cos(i + radians + 0.03) * size_a + rect.height / 2
                )
            )
            p.addLine(
                to: CGPoint(
                    x: sin(i + radians + 0.015) * size_m + rect.width / 2,
                    y: cos(i + radians + 0.015) * size_m + rect.height / 2
                )
            )
            p.addLine(
                to: CGPoint(
                    x: sin(i + radians + 0.04) * size_m * 1.01 + rect.width / 2,
                    y: cos(i + radians + 0.04) * size_m * 1.01 + rect.height / 2
                )
            )
            p.addLine(
                to: CGPoint(
                    x: sin(i + radians + 0.03) * size_b + rect.width / 2,
                    y: cos(i + radians + 0.03) * size_b + rect.height / 2
                )
            )
        }
        return p
    }
}

func createDate(year: Int, month: Int, day: Int, hour: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    return components.date!
}

func datetimeToday(hour: Int) -> Date{
    let now = Date()
    var components = Calendar.current.dateComponents([.era, .year, .month, .day, .timeZone, .calendar], from: now)
    components.hour = hour
    components.minute = 0
    components.second = 0
    components.nanosecond = 0
    return components.date!
}

func rainIntensityToLineWidth(_ rain_intensity: RainIntensity) -> Double {
    switch rain_intensity {
        
    case .none:
        return 0
    case .light:
        return 1
    case .moderate:
        return 2
    case .heavy:
        return 3
    case .violent:
        return 5
    }
}

let weekday_number_to_string = [
    1: "Sunday",
    2: "Monday",
    3: "Tuesday",
    4: "Wednesday",
    5: "Thursday",
    6: "Friday",
    7: "Saturday",
]


func datetime_to_degrees(sunrise: Date, sunset: Date, start: Int) -> (Double, Double) {
    let myStart = Double(start).truncatingRemainder(dividingBy: 24) - 0.5
    let from = 1/12 * max(0, Double(sunrise.fractionalHour() - myStart))
    let to = 1/12 * min(11.9, Double(sunset.fractionalHour() - myStart))
    let x = 360/12.0/2
    return (360 * from - x, 360 * to - x)
}

struct Daylight : View {
    var start : Int
    var sunrise: Date?
    var sunset: Date?

    var body : some View {
        if let sunrise = sunrise, let sunset = sunset {
            let (from, to) = datetime_to_degrees(sunrise: sunrise, sunset: sunset, start: start)
            Rays(a: 2.6, b: circle_inner_diameter, ray_density: sun_ray_density, wiggle_a: true, start_degree: from, end_degree: to)
                .stroke(Color.yellow, style: StrokeStyle(lineWidth: 1, lineCap: .butt))
        }
        else {
            Text("")
        }
    }
}

struct Night : View {
    var start : Int
    var sunrise: Date?
    var sunset: Date?

    var body : some View {
        if let sunrise = sunrise, let sunset = sunset {
            let (from, to) = datetime_to_degrees(sunrise: sunrise, sunset: sunset, start: start)
            if start % 24 == 0 {
                StarRays(ray_density: star_density, start_degree: -15, end_degree: from)
                //.stroke(Color.white, style: StrokeStyle(lineWidth: 1, lineCap: .butt))
                .fill(Color.white)
            }
            else {
                StarRays(ray_density: star_density, start_degree: to, end_degree: 360 - 15)
                //.stroke(Color.white, style: StrokeStyle(lineWidth: 1, lineCap: .butt))
                .fill(Color.white)
            }
        }
        else {
            Text("")
        }
    }
}

func color_from_temperature(_ temp: Float) -> Color {
    if temp < 0 {
        return Color(cold)
    }
    if temp < 20 {
        return Color(coldish)
    }
    if temp > 30 {
        return Color(hot)
    }
    if temp > 26 {
        return Color(warmer)
    }
    if temp > 25 {
        return Color(warm)
    }
    return Color(nice)
}

struct Temperature : View {
    var weather : Weather
    var start : Int
    var frame : CGSize
    let id : Int
    let unit: String
    
    func temperature(weather: Weather) -> Int {
        if unit == "F" {
            return Int(weather.temperature * 9 / 5 + 32)
        }
        else {
            return Int(round(weather.temperature))
        }
    }

    var body : some View {
        let radians : CGFloat = CGFloat.pi - 2.0 * CGFloat.pi / 12.0 * CGFloat(id)
        let size : CGFloat = frame.height * 0.45
        let x: CGFloat = sin(radians) * size + frame.width / 2 - 2
        let y: CGFloat = cos(radians) * size + frame.height / 2 - 2 + 4
        
        #if os(watchOS)
        let iconSize = frame.height / 4.5
        #else
        let iconSize = frame.height / 5.0
        #endif

        let textX = x + 3.0
    
        let font = Font.system(size: iconSize / 3.2)
        let temperature = Text("\(self.temperature(weather: weather))°")
        temperature
            .font(font)
            .position(x: textX, y: y)
            .foregroundColor(color_from_temperature(self.weather.temperature))
    }
}

let hour_slice = 360/12

func hourToStartDegree(hour: Int) -> Int {
    assert(hour >= 0)
    assert(hour <= 24)
    if hour > 12 {
        return hourToStartDegree(hour: hour - 12)
    }
    let x = hour * hour_slice
    return x - hour_slice / 2
}

func hourToEndDegree(hour: Int) -> Int {
    return hourToStartDegree(hour: hour) + hour_slice
}

func rainDegrees(date: Date) -> (Double, Double) {
    let k = date.hour() % 12
    let mid = Double(k * 30)
    let x: Double = k == 11 ? 2.1 : 0
    return (mid - 15.0, mid + 15.0 - x)
}

struct Clock : View {
    var now: Date;
    var startOfToday: Date;
    var showDials: Bool
    var start : Int
    var weather : [Date: Weather]
    let calendar = Calendar.current
    var sunrise : [NaiveDate: Date]
    var sunset : [NaiveDate: Date]
    let unit : String


    var body : some View {
        GeometryReader { (geometry) in
            let frame = geometry.size
            let startTime = startOfToday.addingTimeInterval(TimeInterval(start * 60 * 60))
            let components = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: now)
            let minutes = Double(components.minute!)
            let hour = now.fractionalHour()
    //        let seconds = Double(components.second!) + Double(components.nanosecond!) / 1_000_000_000.0
            let strokeWidth = frame.height / 70
            let weekday = calendar.dateComponents([.weekday], from: startTime).weekday!
            let weekdayStr: String = start == 0 ? "Today" : start % 24 == 0 ? weekday_number_to_string[weekday]! : ""
            
            let cloud_size: CGFloat = geometry.size.height / 23

            
            ZStack {
                Night(start: start, sunrise: sunrise[startTime.getNaiveDate()], sunset: sunset[startTime.getNaiveDate()])
                Daylight(start: start, sunrise: sunrise[startTime.getNaiveDate()], sunset: sunset[startTime.getNaiveDate()])
                #if !os(watchOS)
                VStack {
                    Text("\(weekdayStr)").frame(maxWidth: .infinity, alignment: .leading)
                    .font(Font.system(size: 10))
                    .padding()
                    Spacer()
                }
                #endif
                
                ForEach(0..<12, id: \.self) { id in
                    let startDatetime = startOfToday.addingTimeInterval(TimeInterval((id + start) * 60 * 60))
                    if let weather = weather[startDatetime] {
                        let (from, to) = rainDegrees(date: startDatetime)

                        let isNightTime = true
                        // Bool = (
//                        middleOfHour < sunrise[startTime.getNaiveDate()] ?? true
//                        ||
//                        middleOfHour > sunset[startTime.getNaiveDate()] ?? true
//                        middleOfHour > sunset[startTime.getNaiveDate()] ?? true
//                    )
                        
                        if weather.weatherType == .clear && isNightTime {
                            
                        }
                        
                        // Rain
                        
                        let rain  = weather.rainMillimeter > 0 || weather.weatherType == .rain
                        
                        let darkClouds = rain || weather.weatherType == .lightning || weather.weatherType == .cloud
                    
                        if weather.weatherType == .fog {
                            let blur_radius = frame.height / 60
                            Rays(a: cloud_diameter, b: circle_inner_diameter, ray_density: fog_density - 0.5, wiggle_a: true, wiggle_b: true, start_degree: from-1, end_degree: to+1, wiggle_size: 1.02)
                                .stroke(Color.black.opacity(0.7), style: StrokeStyle(lineWidth: 3, lineCap: .butt, dash: [2, ])).blur(radius: blur_radius)
                            Rays(a: cloud_diameter, b: circle_inner_diameter + 1.5, ray_density: fog_density - 0.5, wiggle_a: true, wiggle_b: true, start_degree: from-1, end_degree: to+1)
                                .stroke(fog_color.opacity(0.5), style: StrokeStyle(lineWidth: 4, lineCap: .butt, dash: [2,])).blur(radius: blur_radius)
                            Rays(a: cloud_diameter, b: circle_inner_diameter, ray_density: fog_density, wiggle_a: true, wiggle_b: true, start_degree: from-1, end_degree: to)
                                .stroke(fog_color, style: StrokeStyle(lineWidth: 1, lineCap: .butt, dash: [1, 1])).blur(radius: blur_radius)
                        }

                        if darkClouds {
                            // black anti-rays
                            Rays(a: cloud_diameter, b: circle_inner_diameter, ray_density: sun_ray_density, start_degree: from, end_degree: to )
                                .stroke(Color.black, style: StrokeStyle(lineWidth: min(geometry.size.height/2, geometry.size.width) / 50, lineCap: .round))
                        }
                        if rain {
                            if weather.weatherType == .snow {
                                Rays(a: cloud_diameter, b: circle_inner_diameter, ray_density: rain_density, wiggle_a: true, wiggle_b: true, start_degree: from, end_degree: to)
                                    .stroke(snow_color, style: StrokeStyle(lineWidth: 1, lineCap: .butt, dash: [1, 4, 1, 4]))
                            }
                            else {
                                // rain
                                Rays(a: cloud_diameter, b: circle_inner_diameter, ray_density: rain_density, wiggle_a: true, wiggle_b: true, start_degree: from, end_degree: to)
                                    .stroke(rainColor, style: StrokeStyle(lineWidth: rainIntensityToLineWidth(weather.rainIntensity), lineCap: .butt, dash: [2]))
                            }
                        }
                        
                        if weather.weatherType == .lightning {
                            Bolt(a: bolt_diameter, b: bolt_diameter2, start_degree: from, end_degree: to).stroke(lightning_color)
                        }
                        
                        if !rain && weather.weatherType == .lightCloud  {
                            Rays(a: cloud_diameter - dark_cloud_border_offset, b: cloud_diameter2 - dark_cloud_border_offset, ray_density: cloud_ray_density, wiggle_c: true, start_degree: from + 0.5, end_degree: to + 0.5, wiggle_size: cloud_wiggle_size)
                                .stroke(Color.black, style: StrokeStyle(lineWidth: cloud_size, lineCap: .round))

                            // white clouds
                            Rays(a: cloud_diameter, b: cloud_diameter2, ray_density: cloud_ray_density, wiggle_a: false, wiggle_b: true, start_degree: from + 0.5, end_degree: to + 0.5, wiggle_size: cloud_wiggle_size)
                                .stroke(Color.white, style: StrokeStyle(lineWidth: cloud_size, lineCap: .round))
                        }
                        if darkClouds {
                            Rays(a: cloud_diameter - dark_cloud_border_offset, b: cloud_diameter2 - dark_cloud_border_offset, ray_density: cloud_ray_density, wiggle_c: true, start_degree: from + 0.5, end_degree: to + 0.5, wiggle_size: cloud_wiggle_size)
                                .stroke(Color.black, style: StrokeStyle(lineWidth: cloud_size, lineCap: .round))

                            // dark clouds
                            Rays(a: cloud_diameter, b: cloud_diameter2, ray_density: cloud_ray_density, wiggle_c: true, start_degree: from + 0.5, end_degree: to + 0.5, wiggle_size: cloud_wiggle_size)
                                .stroke(dark_cloud_color, style: StrokeStyle(lineWidth: cloud_size, lineCap: .round))
                        }
                        
//                        if weather.weatherType == .wind {
//                            let time = datetimeToday(hour: id + start)
//                            let hour = Calendar.current.dateComponents([.hour], from: time).hour!
//                            let radians : CGFloat = CGFloat.pi - 2.0 * CGFloat.pi / 12.0 * CGFloat(id)
//                            let size : CGFloat = frame.height * 0.31
//                            let x = sin(radians) * size + frame.width / 2
//                            let y = cos(radians) * size + frame.height / 2
//                            Wind().stroke(Color.black, lineWidth: 44).fill(Color.gray).rotationEffect(Angle.degrees(Double(hour) * 30.0)).scaleEffect(0.07).position(x: x, y: y)
//                        }

                        Temperature(weather: weather, start: start, frame: frame, id: id, unit: unit)
                    }
                }
                // ground, or circle showing the break in the timeline
                Circle()
                    .trim(from: 0.0, to: 0.99)
                    .rotation(Angle.degrees(-105))
                    .fill(Color.black)
                    .stroke(Color.init(white: 0.3), lineWidth: 1)
                    .padding(frame.height * 0.2)
                    .scaleEffect(0.9)
                
                // Hours strings
                ForEach(0..<12, id: \.self) { id in
                    let time = datetimeToday(hour: id + start)
                    let hour = Calendar.current.dateComponents([.hour], from: time).hour!
                    let radians : CGFloat = CGFloat.pi - 2.0 * CGFloat.pi / 12.0 * CGFloat(id)
                    let size : CGFloat = frame.height * 0.225
                    let x = sin(radians) * size + frame.width / 2
                    let y = cos(radians) * size + frame.height / 2
                    Text("\(hour)").position(x: x, y: y)
                    .foregroundColor(Color.init(white: 0.4))
                    .font(Font.system(size: frame.height / 25.0))
                }
                // Hour and minute dials
                if showDials {
                    ClockDial(now: now, progress: hour / 12.0, extraSize: 0.25).stroke(Color.white, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                    ClockDial(now: now, progress: minutes / 60.0, extraSize: 0.45).stroke(Color.white, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                    // second
    //                ClockDial(now: now, progress: seconds / 60.0, extraSize: 0.5).stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
            }
            #if os(watchOS)
                .scaleEffect(1.4)
            #endif
        }
    }
}


struct Foo : View {
    let weather : [Date: Weather]
    let height : CGFloat
    let hour : Int
    let now : Date
    let size : CGSize
    var sunrise : [NaiveDate: Date]
    var sunset : [NaiveDate: Date]
    let unit: String
    let coordinate: CLLocationCoordinate2D?
    
    var body: some View {
        let fractionalHour: Double = now.fractionalHour()
        let startOfToday = now.set(hour: 0, minute: 0)!
        GeometryReader { (geometry) in
            TabView {
#if os(watchOS)
                ForEach(0..<12, id: \.self) { id in
                    let start1 = 12*id
                    Clock(
                        now: now,
                        showDials: fractionalHour > (start1 - 0.5) && fractionalHour < (start1 + 12 - 0.5),
                        start: start1,
                        weather: weather,
                        sunrise: sunrise,
                        sunset: sunset,
                        unit: unit
                    )
                }
#else
                ForEach(0..<6, id: \.self) { day in
                    ZStack {
                        HStack {
                            Spacer()
                            let moon_size = min(geometry.size.height/2, geometry.size.width) / 6.0
                            
                            Moon(date: now.addingTimeInterval(TimeInterval(day * 24 * 60 * 60))).frame(width: moon_size, height: moon_size).rotationEffect(Angle(degrees: (coordinate?.latitude ?? 0) - 90)).padding(20)
                        }
                        
                        VStack {
                            let i: Int = day * 2
                            let start1: Int = 12*i
                            let start2: Int = 12*(i + 1)
                            let start1_d = Double(start1)
                            let start2_d = Double(start2)
                            Clock(
                                now: now,
                                startOfToday: startOfToday,
                                showDials: fractionalHour > (start1_d - 0.5) && fractionalHour < (start1_d + 12 - 0.5),
                                start: start1,
                                weather: weather,
                                sunrise: sunrise,
                                sunset: sunset,
                                unit: unit
                            ).frame(height: height)
                            Clock(
                                now: now,
                                startOfToday: startOfToday,
                                showDials: fractionalHour > (start2_d - 0.5) && fractionalHour < (start2_d + 12 - 0.5),
                                start: start2,
                                weather: weather,
                                sunrise: sunrise,
                                sunset: sunset,
                                unit: unit
                            ).frame(height: height)
                        }
                    }
                }
#endif
            }
            #if targetEnvironment(macCatalyst)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            #else
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            #endif
            .frame(width: size.width, height: size.height)
        }
    }
}

class UserSettings: ObservableObject {
    @Published var hasChosenUnit: Bool {
        didSet {
            UserDefaults.standard.set(hasChosenUnit, forKey: "hasChosenUnit")
        }
    }
    
    @Published var unit: String {
        didSet {
            UserDefaults.standard.set(unit, forKey: "unit")
        }
    }
    
    init() {
        self.hasChosenUnit = UserDefaults.standard.bool(forKey: "hasChosenUnit")
        self.unit = UserDefaults.standard.string(forKey: "unit") ?? "C"
    }
}

enum WeatherSource {
    case real
    case fake
    case demo
}

struct FrejView: View {
    @State var now: Date = Date()
    @StateObject var locationProvider = LocationProvider()
    @State var coordinate: CLLocationCoordinate2D?
    @State var weather : [Date: Weather] = [:]
    @State var sunrise : [NaiveDate: Date] = [:]
    @State var sunset : [NaiveDate: Date] = [:]
    @State var cancellableLocation : AnyCancellable?
    @State var loadedURL : String = ""
    @State var timeOfData : Date = Date.init(timeIntervalSince1970: 0)
    @State var currentLocation : String = ""
    @State var showUnitChooser = false
    @ObservedObject var userSettings = UserSettings()
    @State var weatherSource: WeatherSource = .real

    let timer = Timer.publish(
        // seconds
        every: 10, // 0.05 to get a smooth second counter
        on: .main,
        in: .common
    ).autoconnect()
        // .background(Rectangle().fill(Color.black))
    var body: some View {
        if showUnitChooser {
            VStack {
                Button(action: {
                    userSettings.unit = "C"
                    userSettings.hasChosenUnit = true
                    showUnitChooser = false
                }) {
                    Text("Celsius").font(Font.system(size: 40)).padding()
                }
                Button(action: {
                    userSettings.unit = "F"
                    userSettings.hasChosenUnit = true
                    showUnitChooser = false
                }) {
                    Text("Fahrenheit").font(Font.system(size: 40))
                }
            }.preferredColorScheme(ColorScheme.dark)
        }
        else {
            let calendar = Calendar.current
            let components = calendar.dateComponents([Calendar.Component.hour], from: now)
            let hour = components.hour!
            
            VStack {
#if !os(watchOS)
                Spacer()
                Text(currentLocation).font(Font.system(size: 25))
                Link("Weather data by Open-Meteo.com", destination: URL(string: "https://open-meteo.com/")!).font(Font.system(size: 12)).foregroundColor(Color.gray)
#endif
                GeometryReader { (geometry) in
                    let size = geometry.size
                    let height = min(size.width * 0.9, abs(size.height / 2 - 25))
                    Foo(weather: weather, height: height, hour: hour, now: now, size: size, sunrise: sunrise, sunset: sunset, unit: userSettings.unit, coordinate: coordinate)
                }
#if os(iOS)
                .ignoresSafeArea(SafeAreaRegions.all, edges: .bottom)
#endif
                .preferredColorScheme(ColorScheme.dark)
                .onAppear {
                    startLocationTracking()
                    fetchWeather()
                }
            }
            .onReceive(timer) { input in
                now = input
                if now.distance(to: timeOfData) > 60 * 60 {
                    timeOfData = now
                    fetchWeather()
                }
            }
        
        }
    }
    
    func getWeather(hour: Int) -> Weather? {
        guard let date = Date().set(hour: hour) else {
            return nil
        }
        return self.weather[date]
    }
    
    func fetchWeather() {
        // weatherFromSMI()
        switch self.weatherSource {
        case .fake:
            fakeWeather()
        case .real:
            weatherFromOpenMeteo()
        case .demo:
            demoWeather()
        }
    }
    
    func fakeWeather() {
        let now = Date()
        self.sunrise[now.getNaiveDate()] = now.set(hour: 6, minute: 20)
        self.sunset[now.getNaiveDate()] = now.set(hour: 20, minute: 10)
        // AM
        self.weather[now.set(hour:  0)!] = Weather(time: now.set(hour:  0)!, temperature:   1, weatherType:        .snow, rainMillimeter:  1, isDay: false)
        self.weather[now.set(hour:  1)!] = Weather(time: now.set(hour:  1)!, temperature: -11, weatherType: .mainlyClear, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour:  2)!] = Weather(time: now.set(hour:  2)!, temperature:  10, weatherType:       .clear, rainMillimeter:  1, isDay: false)
        self.weather[now.set(hour:  3)!] = Weather(time: now.set(hour:  3)!, temperature:  15, weatherType:   .lightning, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour:  4)!] = Weather(time: now.set(hour:  4)!, temperature:  20, weatherType:   .lightning, rainMillimeter:  9, isDay: false)
        self.weather[now.set(hour:  5)!] = Weather(time: now.set(hour:  5)!, temperature:  26, weatherType:       .cloud, rainMillimeter:100, isDay: false)
        self.weather[now.set(hour:  6)!] = Weather(time: now.set(hour:  6)!, temperature:  27, weatherType:.  lightCloud, rainMillimeter:  1, isDay: false)
        self.weather[now.set(hour:  7)!] = Weather(time: now.set(hour:  7)!, temperature:  32, weatherType:        .rain, rainMillimeter:  0, isDay:  true)
        self.weather[now.set(hour:  8)!] = Weather(time: now.set(hour:  8)!, temperature:   8, weatherType:        .wind, rainMillimeter: 0, isDay:  true)
        self.weather[now.set(hour:  9)!] = Weather(time: now.set(hour:  9)!, temperature:   9, weatherType:       .cloud, rainMillimeter:  0, isDay:  true)
        self.weather[now.set(hour: 10)!] = Weather(time: now.set(hour: 10)!, temperature:  10, weatherType:   .lightning, rainMillimeter:  0, isDay:  true)
        self.weather[now.set(hour: 11)!] = Weather(time: now.set(hour: 11)!, temperature:  11, weatherType:         .fog, rainMillimeter: 10, isDay:  true)
        // PM
        self.weather[now.set(hour: 12)!] = Weather(time: now.set(hour: 12)!, temperature:  12, weatherType:         .fog, rainMillimeter:  0, isDay:  true)
        self.weather[now.set(hour: 13)!] = Weather(time: now.set(hour: 13)!, temperature:  13, weatherType:   .lightning, rainMillimeter: 10, isDay:  true)
        self.weather[now.set(hour: 14)!] = Weather(time: now.set(hour: 14)!, temperature:  14, weatherType:       .clear, rainMillimeter: 10, isDay:  true)
        self.weather[now.set(hour: 15)!] = Weather(time: now.set(hour: 15)!, temperature:  16, weatherType:  .lightCloud, rainMillimeter:  10, isDay:  true)
        self.weather[now.set(hour: 16)!] = Weather(time: now.set(hour: 16)!, temperature: -23, weatherType:  .lightCloud, rainMillimeter: 10, isDay:  true)
        self.weather[now.set(hour: 17)!] = Weather(time: now.set(hour: 17)!, temperature: -12, weatherType:  .lightCloud, rainMillimeter:  0, isDay:  true)
        self.weather[now.set(hour: 18)!] = Weather(time: now.set(hour: 18)!, temperature:  17, weatherType:        .wind, rainMillimeter: 10, isDay:  true)
        self.weather[now.set(hour: 19)!] = Weather(time: now.set(hour: 19)!, temperature:  24, weatherType:       .cloud, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour: 20)!] = Weather(time: now.set(hour: 20)!, temperature:  35, weatherType:   .lightning, rainMillimeter:  1, isDay: false)
        self.weather[now.set(hour: 21)!] = Weather(time: now.set(hour: 21)!, temperature:   1, weatherType:          .fog, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour: 22)!] = Weather(time: now.set(hour: 22)!, temperature:  10, weatherType:         .fog, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour: 23)!] = Weather(time: now.set(hour: 23)!, temperature:  13, weatherType:         .fog, rainMillimeter:  0, isDay: false)
    }
    
    func demoWeather() {
        let now = Date()
        self.sunrise[now.getNaiveDate()] = now.set(hour: 6, minute: 20)
        self.sunset[now.getNaiveDate()] = now.set(hour: 19, minute: 30)
        // AM
        self.weather[now.set(hour:  0)!] = Weather(time: now.set(hour:  0)!, temperature:   1, weatherType:        .clear, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour:  1)!] = Weather(time: now.set(hour:  1)!, temperature:  -1, weatherType: .mainlyClear, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour:  2)!] = Weather(time: now.set(hour:  2)!, temperature:  3, weatherType:       .clear, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour:  3)!] = Weather(time: now.set(hour:  3)!, temperature:  7, weatherType:   .clear, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour:  4)!] = Weather(time: now.set(hour:  4)!, temperature:  14, weatherType:   .lightCloud, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour:  5)!] = Weather(time: now.set(hour:  5)!, temperature:  18, weatherType:   .lightCloud, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour:  6)!] = Weather(time: now.set(hour:  6)!, temperature:  20, weatherType:.  lightCloud, rainMillimeter:  1, isDay: false)
        self.weather[now.set(hour:  7)!] = Weather(time: now.set(hour:  7)!, temperature:  20, weatherType:        .rain, rainMillimeter:  5, isDay:  true)
        self.weather[now.set(hour:  8)!] = Weather(time: now.set(hour:  8)!, temperature:  19, weatherType:        .rain, rainMillimeter: 10, isDay:  true)
        self.weather[now.set(hour:  9)!] = Weather(time: now.set(hour:  9)!, temperature:  20, weatherType:       .rain, rainMillimeter:  1, isDay:  true)
        self.weather[now.set(hour: 10)!] = Weather(time: now.set(hour: 10)!, temperature:  19, weatherType:   .lightCloud, rainMillimeter:  0, isDay:  true)
        self.weather[now.set(hour: 11)!] = Weather(time: now.set(hour: 11)!, temperature:  17, weatherType:         .lightCloud, rainMillimeter: 0, isDay:  true)
        // PM
        self.weather[now.set(hour: 12)!] = Weather(time: now.set(hour: 12)!, temperature:  23, weatherType:         .clear, rainMillimeter:  0, isDay:  true)
        self.weather[now.set(hour: 13)!] = Weather(time: now.set(hour: 13)!, temperature:  25, weatherType:   .clear, rainMillimeter: 0, isDay:  true)
        self.weather[now.set(hour: 14)!] = Weather(time: now.set(hour: 14)!, temperature:  24, weatherType:       .clear, rainMillimeter: 0, isDay:  true)
        self.weather[now.set(hour: 15)!] = Weather(time: now.set(hour: 15)!, temperature:  27, weatherType:  .lightCloud, rainMillimeter:  0, isDay:  true)
        self.weather[now.set(hour: 16)!] = Weather(time: now.set(hour: 16)!, temperature:  26, weatherType:  .lightCloud, rainMillimeter: 0, isDay:  true)
        self.weather[now.set(hour: 17)!] = Weather(time: now.set(hour: 17)!, temperature:  32, weatherType:  .lightCloud, rainMillimeter:  0, isDay:  true)
        self.weather[now.set(hour: 18)!] = Weather(time: now.set(hour: 18)!, temperature:  30, weatherType:        .wind, rainMillimeter: 0, isDay:  true)
        self.weather[now.set(hour: 19)!] = Weather(time: now.set(hour: 19)!, temperature:  28, weatherType:       .clear, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour: 20)!] = Weather(time: now.set(hour: 20)!, temperature:  23, weatherType:   .clear, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour: 21)!] = Weather(time: now.set(hour: 21)!, temperature:  20, weatherType:          .clear, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour: 22)!] = Weather(time: now.set(hour: 22)!, temperature:  16, weatherType:         .clear, rainMillimeter:  0, isDay: false)
        self.weather[now.set(hour: 23)!] = Weather(time: now.set(hour: 23)!, temperature:  18, weatherType:         .clear, rainMillimeter:  0, isDay: false)
    }
    func startLocationTracking() {
        do {
            locationProvider.lm.allowsBackgroundLocationUpdates = false
            try locationProvider.start()
        }
        catch {
            print("No location access.")
            locationProvider.requestAuthorization()
            do {
                try locationProvider.start()
            }
            catch {
            }
        }
    }
 
    func weatherFromOpenMeteo() {
        cancellableLocation = locationProvider.locationWillChange.sink { loc in
            let geocoder = CLGeocoder()
            coordinate = loc.coordinate
            geocoder.reverseGeocodeLocation(loc) { (placemarks, error) in
                if error == nil {
                    let firstLocation = placemarks?[0]
                    currentLocation = firstLocation?.locality ?? ""
                    
                    if firstLocation?.country ?? "unknown" == "United States" && !userSettings.hasChosenUnit {
                        showUnitChooser = true
                    }
                }
            }

            // handleLocation(loc)
            DispatchQueue.main.async {
                let s = "https://api.open-meteo.com/v1/forecast?latitude=\(loc.coordinate.latitude)&longitude=\(loc.coordinate.longitude)&hourly=temperature_2m,precipitation,weathercode,cloudcover,windspeed_10m&past_days=1&daily=sunrise,sunset&timezone=UTC&timeformat=unixtime"
                guard s != loadedURL && timeOfData.distance(to: Date()) > 60*60 else {  // don't update more than once an hour
                    return
                }
                guard let url = URL(string: s) else {
                    return
                }
                loadedURL = s
                
                print("getting: \(url)")
                let request = URLRequest(url: url)
                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if let response = response as? HTTPURLResponse {
                        
                        if response.statusCode == 503 {
                            return
                        }
                        
                       if error != nil {
                            return
                        }
                        
                        do {
                            if let data = data {
                                let string1 = String(data: data, encoding: String.Encoding.utf8) ?? "Data could not be printed"
                                print(string1)
                                let decoder = JSONDecoder()
                                
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
                                
                                decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.secondsSince1970
                                let result = try decoder.decode(OMWeatherData.self, from: data)
                                print("Parsed!")
                                
                                for sunset_item in result.daily.sunset {
                                    self.sunset[sunset_item.getNaiveDate()] = sunset_item
                                }
                                for sunrise_item in result.daily.sunrise {
                                    self.sunrise[sunrise_item.getNaiveDate()] = sunrise_item
                                }

                                for i in 0..<result.hourly.time.count {
                                    let time = result.hourly.time[i]
                                    let temperature = result.hourly.temperature_2m[i]
                                    let weatherSymbol = result.hourly.weathercode[i]
                                    let rainMillimeter = result.hourly.precipitation[i]
                                    let windspeed = result.hourly.windspeed_10m[i]
                                    let sunrise = self.sunrise[time.getNaiveDate()]
                                    let sunset = self.sunset[time.getNaiveDate()]
                                    guard let sunrise = sunrise else {
                                        continue
                                    }
                                    guard let sunset = sunset else {
                                        continue
                                    }
                                    let isDay = time > sunrise && time < sunset
                                                                     
                                    /*
                                     0              Clear sky
                                     1, 2, 3        Mainly clear, partly cloudy, and overcast
                                     45, 48         Fog and depositing rime fog
                                     51, 53, 55     Drizzle: Light, moderate, and dense intensity
                                     56, 57         Freezing Drizzle: Light and dense intensity
                                     61, 63, 65     Rain: Slight, moderate and heavy intensity
                                     66, 67         Freezing Rain: Light and heavy intensity
                                     71, 73, 75     Snow fall: Slight, moderate, and heavy intensity
                                     77             Snow grains
                                     80, 81, 82     Rain showers: Slight, moderate, and violent
                                     85, 86         Snow showers slight and heavy
                                     95 *           Thunderstorm: Slight or moderate
                                     96, 99 *       Thunderstorm with slight and heavy hail
                                     */
                                    
                                    var weatherType : WeatherType
                                    switch weatherSymbol {
                                    case 0:
                                        weatherType = .clear
                                    case 1:
                                        weatherType = .mainlyClear
                                    case 2:
                                        weatherType = .lightCloud
                                    case 3:
                                        weatherType = .cloud
                                    case 71...75:
                                        weatherType = .snow
                                    case 51...67:
                                        weatherType = .rain
                                    case 80...86:
                                        weatherType = .rain
                                    case 95...99:
                                        weatherType = .lightning
                                    case 45...48:
                                        weatherType = .fog
                                    default:
                                        weatherType = .unknown
                                    }
                                    
                                    if windspeed > 20 {
                                        weatherType = .wind
                                    }
                                    
                                    self.weather[time] = Weather(time: time, temperature: temperature, weatherType: weatherType, rainMillimeter: rainMillimeter, isDay: isDay)
                                }
                            }
                        }
                        catch let error {
                            print("Error parsing (\(error))")
                        }
                    }
                }
                task.resume()
            }
        }
    }
}


struct Previews_FrejView_Previews: PreviewProvider {
    static var previews: some View {
        FrejView(weatherSource: .fake)
    }
}
