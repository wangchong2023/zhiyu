import Observation
import Foundation

@Observable
class MyModel {}

func test(model: any Observable) {
    print("Success")
}

let m = MyModel()
test(model: m)
