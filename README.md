## markup

学习编译原理，用来练手的 Parser 小项目。

parser 的工作即是将代码片段转换成计算机可读的数据结构的过程。这个“计算机可读的数据结构”更专业的说法是“抽象语法树（abstract syntax tree）”，简称AST。
AST 是代码片段具体语义的抽象表达，它不包含该段代码的所有细节，比如缩进、换行这些细节，所以，我们可以使用 parser 转换出 AST。

## Parser 的结构

一般来说，一个 parser 会由两部分组成：

* 词法解析器(lexer/scanner/tokenizer)
* 对应语法的解释器（parser）

在解释某段代码的时候，先由词法解释器将代码段转化成一个一个的词组流（token），再交由解释器对词组流进行语法解释，转化为对应语法的抽象解释，即是 AST 了。

从根节点从上向下，不断递归，识别根节点的过程。这个解析的过程也被称为**递归下降解析器**。

## 项目功能

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
