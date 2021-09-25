// https://stackoverflow.com/questions/57334125/how-to-make-text-stroke-in-swiftui
// https://www.smhi.se/data/oppna-data/meteorologiska-data/api-for-vaderprognosdata-1.34233

// https://opendata-download-metfcst.smhi.se/api/category/pmp3g/version/2/geotype/point/lon/16.158/lat/58.5812/data.json
// json data:
//      t : temperature C
//      ws : wind speed m/s
//      tcc_mean : Mean value of total cloud cover (0-9)
//      pmin: Minimum precipitation intensity (mm/h)
//      pmax: Maximum precipitation intensity (mm/h)
//      pcat: Precipitation Category
//            0    No precipitation
//            1    Snow
//            2    Snow and rain
//            3    Rain
//            4    Drizzle
//            5    Freezing rain
//            6    Freezing drizzle
//      Wsymb2: Weather symbol
//            1    Clear sky
//            2    Nearly clear sky
//            3    Variable cloudiness
//            4    Halfclear sky
//            5    Cloudy sky
//            6    Overcast
//            7    Fog
//            8    Light rain showers
//            9    Moderate rain showers
//           10    Heavy rain showers
//           11    Thunderstorm
//           12    Light sleet showers
//           13    Moderate sleet showers
//           14    Heavy sleet showers
//           15    Light snow showers
//           16    Moderate snow showers
//           17    Heavy snow showers
//           18    Light rain
//           19    Moderate rain
//           20    Heavy rain
//           21    Thunder
//           22    Light sleet
//           23    Moderate sleet
//           24    Heavy sleet
//           25    Light snowfall
//           26    Moderate snowfall
//           27    Heavy snowfall

import SwiftUI
import CoreLocation
import Combine


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


struct Clock : View {
    var now: Date;
    var showDials: Bool
    @State var frame: CGSize = .zero
    var start : Int
    var weather : [Date: Weather]
    
    var body : some View {
        let calendar = Calendar.current
        let components = calendar.dateComponents([Calendar.Component.hour, Calendar.Component.minute, Calendar.Component.second, Calendar.Component.nanosecond], from: now)
        let hour = Double(components.hour!)
        let minutes = Double(components.minute!)
//        let seconds = Double(components.second!) + Double(components.nanosecond!) / 1_000_000_000.0
        let color = showDials ? Color.white : Color.black

        ZStack {
            GeometryReader { (geometry) in
                self.makeView(geometry)
            }
            ClockDial(now: now, progress: hour / 12, extraSize: 0.4).stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
            ClockDial(now: now, progress: minutes / 60.0, extraSize: 0.7).stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
//            ClockDial(now: now, progress: seconds / 60.0, extraSize: 0.9).stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            ForEach(0..<12, id: \.self) { id in
                let weather = weather[datetimeToday(hour: id + start)]
                
                let radians : CGFloat = CGFloat.pi - 2.0 * CGFloat.pi / 12.0 * CGFloat(id)
                let size : CGFloat = frame.height / 2.0 * 1.17
                let x = sin(radians) * size + frame.width / 2
                let y = cos(radians) * size + frame.height / 2
                
                if let weather = weather {
                    ZStack {
                        weather.icon()
                            .frame(width: 60, height: 60)
                            .position(x: x, y: y)
                            .foregroundColor(weather.iconColor())

                        Text("\(Int(weather.temperature))°")
                            .font(.system(size: 20))
                            .position(x: x + 3, y: y)
                            .foregroundColor(weather.textColor())
                            .shadow(color: .black, radius: 0.5)
                            .shadow(color: .black, radius: 0.5)
                            .shadow(color: .black, radius: 0.5)
                            .shadow(color: .black, radius: 0.5)
                    }
                }
                else {
                    Text("")
                }
            }
            ForEach(0..<12, id: \.self) { id in
                let radians : CGFloat = CGFloat.pi - 2.0 * CGFloat.pi / 12.0 * CGFloat(id)
                let size : CGFloat = frame.height / 2.0 * 0.74
                let x = sin(radians) * size + frame.width / 2
                let y = cos(radians) * size + frame.height / 2
                let title = id == 0 ? 12 : id
                Text("\(title)").position(x: x, y: y).foregroundColor(Color.init(white: 0.4))
            }
        }
        .background(Circle().trim(from: 0.0, to: 0.98).rotation(.degrees(-102)).stroke(Color.white)).foregroundColor(Color.white)
        .padding(65)
    }
    
    func makeView(_ geometry: GeometryProxy) -> some View {
        DispatchQueue.main.async { self.frame = geometry.size }
        return Text("")
    }
}


struct ContentView: View {
    @State var now: Date = Date()
    @StateObject var locationProvider = LocationProvider()
    @State var weatherDataRaw : WeatherData?
    @State var weather : [Date: Weather] = [:]
    @State var cancellableLocation : AnyCancellable?
    @State var loadedURL : String = ""

    let timer = Timer.publish(
        every: 10,  // seconds
        on: .main,
        in: .common
    ).autoconnect()
    
    var body: some View {
        let calendar = Calendar.current
        let components = calendar.dateComponents([Calendar.Component.hour], from: now)
        
        ScrollView(.vertical){
            VStack {
                Clock(now: now, showDials: components.hour! <= 12, start: 0, weather: weather).frame(height: 350)
                Clock(now: now, showDials: components.hour! > 12, start: 12, weather: weather).frame(height: 350)
                Clock(now: now, showDials: components.hour! > 24, start: 24, weather: weather).frame(height: 350)
//                Clock(now: now, showDials: components.hour! > 24, start: 36, weather: weather)
            }
        }
        .onReceive(timer) { input in
            now = input
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // TODO !!!
//            weatherFromSMI()
            fakeWeather()
        }
    }
    
    func getWeather(hour: Int) -> Weather? {
        guard let date = Date.now.setHour(hour) else {
            return nil
        }
        return self.weather[date]
    }
    
    func fakeWeather() {
        let now = Date.now
        self.weather[now.setHour( 1)!] = Weather(temperature:   1, weatherType:      .wind, rainMillimeter:  0)
        self.weather[now.setHour( 2)!] = Weather(temperature:  10, weatherType:       .sun, rainMillimeter:  2)
        self.weather[now.setHour( 3)!] = Weather(temperature:  13, weatherType: .lightning, rainMillimeter:  3)
        self.weather[now.setHour( 4)!] = Weather(temperature:  14, weatherType:       .sun, rainMillimeter:  5)
        self.weather[now.setHour( 5)!] = Weather(temperature:  16, weatherType:     .cloud, rainMillimeter:  6)
        self.weather[now.setHour( 6)!] = Weather(temperature: -23, weatherType:      .wind, rainMillimeter:  8)
        self.weather[now.setHour( 7)!] = Weather(temperature: -12, weatherType:      .rain, rainMillimeter:  9)
        self.weather[now.setHour( 8)!] = Weather(temperature:  17, weatherType:      .wind, rainMillimeter: 10)
        self.weather[now.setHour( 9)!] = Weather(temperature:  24, weatherType:     .cloud, rainMillimeter: 20)
        self.weather[now.setHour(10)!] = Weather(temperature:  35, weatherType: .lightning, rainMillimeter: 40)
        self.weather[now.setHour(11)!] = Weather(temperature:   1, weatherType:      .wind, rainMillimeter:  0)
        self.weather[now.setHour(12)!] = Weather(temperature:  10, weatherType:       .sun, rainMillimeter:  2)
        self.weather[now.setHour(13)!] = Weather(temperature:  13, weatherType: .lightning, rainMillimeter:  3)
        self.weather[now.setHour(14)!] = Weather(temperature:  14, weatherType:       .sun, rainMillimeter:  5)
        self.weather[now.setHour(15)!] = Weather(temperature:  16, weatherType:     .cloud, rainMillimeter:  6)
        self.weather[now.setHour(16)!] = Weather(temperature: -23, weatherType:      .wind, rainMillimeter:  8)
        self.weather[now.setHour(17)!] = Weather(temperature: -12, weatherType:      .rain, rainMillimeter:  9)
        self.weather[now.setHour(18)!] = Weather(temperature:  17, weatherType:      .wind, rainMillimeter: 10)
        self.weather[now.setHour(19)!] = Weather(temperature:  24, weatherType:     .cloud, rainMillimeter: 20)
        self.weather[now.setHour(20)!] = Weather(temperature:  35, weatherType: .lightning, rainMillimeter: 40)
        self.weather[now.setHour(21)!] = Weather(temperature:   1, weatherType:      .wind, rainMillimeter:  0)
        self.weather[now.setHour(22)!] = Weather(temperature:  10, weatherType:       .sun, rainMillimeter:  2)
        self.weather[now.setHour(23)!] = Weather(temperature:  13, weatherType: .lightning, rainMillimeter:  3)
        self.weather[now.setHour(24)!] = Weather(temperature:  14, weatherType:       .sun, rainMillimeter:  5)
        self.weather[now.setHour(25)!] = Weather(temperature:  16, weatherType:     .cloud, rainMillimeter:  6)
        self.weather[now.setHour(26)!] = Weather(temperature: -23, weatherType:      .wind, rainMillimeter:  8)
        self.weather[now.setHour(27)!] = Weather(temperature: -12, weatherType:      .rain, rainMillimeter:  9)
        self.weather[now.setHour(28)!] = Weather(temperature:  17, weatherType:      .wind, rainMillimeter: 10)
        self.weather[now.setHour(29)!] = Weather(temperature:  24, weatherType:     .cloud, rainMillimeter: 20)
        self.weather[now.setHour(30)!] = Weather(temperature:  35, weatherType: .lightning, rainMillimeter: 40)
        self.weather[now.setHour(31)!] = Weather(temperature:   1, weatherType:      .wind, rainMillimeter:  0)
        self.weather[now.setHour(32)!] = Weather(temperature:  10, weatherType:       .sun, rainMillimeter:  2)
        self.weather[now.setHour(33)!] = Weather(temperature:  13, weatherType: .lightning, rainMillimeter:  3)
        self.weather[now.setHour(34)!] = Weather(temperature:  14, weatherType:       .sun, rainMillimeter:  5)
        self.weather[now.setHour(35)!] = Weather(temperature:  16, weatherType:     .cloud, rainMillimeter:  6)
        self.weather[now.setHour(36)!] = Weather(temperature: -23, weatherType:      .wind, rainMillimeter:  8)
        self.weather[now.setHour(37)!] = Weather(temperature: -12, weatherType:      .rain, rainMillimeter:  9)
        self.weather[now.setHour(38)!] = Weather(temperature:  17, weatherType:      .wind, rainMillimeter: 10)
        self.weather[now.setHour(39)!] = Weather(temperature:  24, weatherType:     .cloud, rainMillimeter: 20)
    }
        
    // TODO: switch to https://open-meteo.com/en/docs, or in addition to SMHI
    func weatherFromSMI() {
        do {
            try locationProvider.start()
        }
        catch {
            print("No location access.")
            locationProvider.requestAuthorization()
        }
        
        cancellableLocation = locationProvider.locationWillChange.sink { loc in
            // handleLocation(loc)
            DispatchQueue.main.async {
                let s = "https://opendata-download-metfcst.smhi.se/api/category/pmp3g/version/2/geotype/point/lon/\(loc.coordinate.longitude)/lat/\(loc.coordinate.latitude)/data.json"
                guard s != loadedURL else {
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
//                                let string1 = String(data: data, encoding: String.Encoding.utf8) ?? "Data could not be printed"
//                                print(string1)
                                let decoder = JSONDecoder()
                                decoder.dateDecodingStrategy = .iso8601
                                let result = try decoder.decode(WeatherData.self, from: data)
//                                print("Parsed!")
                                self.weatherDataRaw = result
                                
                                for timeslot in result.timeSeries {
                                    var temperature : Float?
                                    var weatherSymbol : Int?
                                    var rainMillimeter : Float?
                                    
                                    for param in timeslot.parameters {
                                        switch param.name {
                                        case "t":
                                            temperature = param.values[0]
                                        case "Wsymb2":
                                            weatherSymbol = Int(param.values[0])
                                        case "pmin":
                                            rainMillimeter = param.values[0]
                                        default:
                                            ()
                                        }
                                    }
                                    
                                    guard let temperature = temperature,
                                          let weatherSymbol = weatherSymbol,
                                          let rainMillimeter = rainMillimeter
                                    else {
                                        continue
                                    }
                                    
                                    //      Wsymb2: Weather symbol
                                    //            1    Clear sky
                                    //            2    Nearly clear sky
                                    //            3    Variable cloudiness
                                    //            4    Halfclear sky
                                    //            5    Cloudy sky
                                    //            6    Overcast
                                    //            7    Fog
                                    //            8    Light rain showers
                                    //            9    Moderate rain showers
                                    //           10    Heavy rain showers
                                    //           11    Thunderstorm
                                    //           12    Light sleet showers
                                    //           13    Moderate sleet showers
                                    //           14    Heavy sleet showers
                                    //           15    Light snow showers
                                    //           16    Moderate snow showers
                                    //           17    Heavy snow showers
                                    //           18    Light rain
                                    //           19    Moderate rain
                                    //           20    Heavy rain
                                    //           21    Thunder
                                    //           22    Light sleet
                                    //           23    Moderate sleet
                                    //           24    Heavy sleet
                                    //           25    Light snowfall
                                    //           26    Moderate snowfall
                                    //           27    Heavy snowfall
                                    let weatherType : WeatherType
                                    switch weatherSymbol {
                                    case 1...4:
                                        weatherType = .sun
                                    case 6...7:
                                        weatherType = .cloud
                                        
                                    case 8...21:
                                        weatherType = .rain
                                    case 21:
                                        weatherType = .lightning
                                    default:
                                        weatherType = .unknown
                                    }

                                    self.weather[timeslot.validTime] = Weather(temperature: temperature, weatherType: weatherType, rainMillimeter: rainMillimeter)
                                }
                            }
                        }
                        catch {
                            print("Error parsing")
                        }
                    }
                }
                task.resume()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
