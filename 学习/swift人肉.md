###### 

```swift
import SwiftUI //为啥要引入这个玩意? 因为app, scene, body都是swiftui提供的.
@main
struct KeyiosApp: App { //这里app是一个协议protocol 
  										//这个{花括号是接口体定义语法
    var body: some Scene { // 这个body是不是类似一个钩子或者抽象类重载? 是的.
      								// 这个{花括号是计算属性, 是getter的方法体, 返回值是scene
       WindowGroup { //这个是不是也是钩子/重载?  这里是按要求构造了一个返回值? 
         							//这里是swiftui提供的WindowGroup新建一个匿名实例对吗? 是
         							//他是body这个计算属性的返回值? swift的返回值不写return? 是, 只有一个表达式的时候可以省略return
         					//这个{花括号是个闭包
            列表v(日记表: 日记表) //这个是WindowGroup的构造函数的参数? 是的
        }
		}
}



```



