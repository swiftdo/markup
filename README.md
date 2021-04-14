## markup

学习编译器，用来练手的小项目：

```
"The *quick*, ~red~ brown fox jumps over a _*lazy dog*_."
```

需要将此解析为：

```
The <strong>quick</strong>, <del>red</del> brown fox jumps over a <i><strong>lazy dog</strong></i>.
```

语法树：

![](http://blog.loveli.site/mweb/16183814046437.jpg)



## 参考
* [Writing a Lightweight Markup Parser in Swift](https://medium.com/makingtuenti/writing-a-lightweight-markup-parser-in-swift-5c8a5f0f793f)