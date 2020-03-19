# （探讨滤波器）1. 在单片机，计算机实现数字滤波器

最近有朋友问我，他们被要求在单片机里实现一个滤波器，参数等要求此处略去不表，他很忧愁怎么在单片机实现滤波器进行滤波操作。

<<<<<<< HEAD
![这个朋友真不是我自己](D:\users\无名\PycharmProjects\data_source\pic\bj8yj.gif)
=======
![这个朋友真不是我自己](https://github.com/maxs-well/FIR_Implementation/blob/master/pic/bj8yj.gif)
>>>>>>> fir_origin/master

我告诉他，只需要Matlab就可，或者说只要你能确定滤波器抽头的系数就可以了。为什么滤波器只需要抽头系数就可以了，这一切都要从滤波器的结构讲起；为了方便讲解，我们选用结构简单的FIR滤波器讲解。

本文通过讲解FIR的系统结构，进而讲解数字滤波器滤波原理和实现方法。文章涉及部分数字信号处理内容，实现方法设计Python语言和Matlab的使用以及部分线性代数的基础知识。

本文所使用的Python项目文件夹开源在Github，链接在文章底部；也可以关注BUG记录公众号（微信号：BugRec）回复106获取项目工程。

------

## 查看FIR滤波器的系统结构

打开Matlab，在命令窗口输入fdatool(新版MATLAB为filterDesigner)回车，Matlab的FIR相关基础操作可以看[（学习Verilog）6. FIR IP核的基础功能使用总结](https://zhuanlan.zhihu.com/p/97236015)

<<<<<<< HEAD
![选择FIR窗函数，72阶，汉宁窗，fs:fc = 10:1](D:\users\无名\PycharmProjects\data_source\pic\1.png)

然后跟着下图的操作顺序来

![按照操作来，接下来需要等待一段时间](D:\users\无名\PycharmProjects\data_source\pic\2.png)

等待一会后会打开Simulink，Simulink会出现下图

![Filter的实现框图，点击它](D:\users\无名\PycharmProjects\data_source\pic\3.png)

点击Filter，会出现下图

![FIR滤波器实现框图](D:\users\无名\PycharmProjects\data_source\pic\4.png)
=======
![选择FIR窗函数，72阶，汉宁窗，fs:fc = 10:1](https://github.com/maxs-well/FIR_Implementation/blob/master/pic/1.png)

然后跟着下图的操作顺序来

![按照操作来，接下来需要等待一段时间](https://github.com/maxs-well/FIR_Implementation/blob/master/pic/2.png)

等待一会后会打开Simulink，Simulink会出现下图

![Filter的实现框图，点击它](https://github.com/maxs-well/FIR_Implementation/blob/master/pic/3.png)

点击Filter，会出现下图

![FIR滤波器实现框图](https://github.com/maxs-well/FIR_Implementation/blob/master/pic/4.png)
>>>>>>> fir_origin/master

各位电脑实际操作的时候可以缩小看，整个滤波器结构其实就是这样子的。外部数据从上进入，然后经过延时到达下一级，我们称每一级为抽头；同一时刻下，抽头的数据会跟抽头系数相乘（图中三角形），然后所有抽头相乘的结构相加就是最后的结果。

为什么这样子就能实现滤波功能？

这里首先告诉大家一个结论，所有滤波器实现的原理，无非是**延时加权求和**，具体的理论细节将在后续讲解，FIR滤波器公式如下：
$$
y(n) =\sum^{N-1}_{n=0}h(n)x(n)
$$
公式看着很简单，也对应上了上述的系统结构，加权（系数相乘），延时，求和。不过，滤波器设计过程中，难点还是在于h(n)的设计实现，好在matlab帮助我们计算出了系数。



## 导出FIR滤波器系数

FIR滤波器实现过程中，最麻烦的系数已经获取到了，接下来我们就需要把系数导出，导出过程如下：

#### 1. 直接导出数据到文本文件

<<<<<<< HEAD
![导出数据](D:\users\无名\PycharmProjects\data_source\pic\6.png)

![保存为txt文件](D:\users\无名\PycharmProjects\data_source\pic\7.png)
=======
![导出数据](https://github.com/maxs-well/FIR_Implementation/blob/master/pic/6.png)

![保存为txt文件](https://github.com/maxs-well/FIR_Implementation/blob/master/pic/7.png)
>>>>>>> fir_origin/master



#### 2. 导出C语言的头文件，直接用在C/C++上

<<<<<<< HEAD
![生成C 头文件](D:\users\无名\PycharmProjects\data_source\pic\8.png)
=======
![生成C 头文件](https://github.com/maxs-well/FIR_Implementation/blob/master/pic/8.png)
>>>>>>> fir_origin/master



由于家里的电脑好久没写C了，Visual Studio2015不知道出什么毛病，写C一直报错；Dev-C++也出现问题，一气之下就用Python3写完了后续过程。为了Python3方便调用，这里我选择了导出方法1。



## 3. 实现代码讲解

实验所用的环境为Python3，需要预先安装Numpy，Matplotlib。

##### 参数设定

```python
# FIR抽头阶数
LEN = 73
# FIR滤波器信号数据延时的数组
fir_data = np.zeros(LEN)
# 制作一个信号源，对比效果
# 采样频率
fs = 10000
```

首先设置FIR的阶数，可能有人会有疑问，上面的图片中FIR的阶数是72，这里怎么是73；由于结构问题，FIR的数据进入的第一级只进行了延时，没有系数相乘，或者说系数相乘0。而FIR的系数保持对称关系，
$$
h(n) = h(N-n)
$$
为了保持这种关系，FIR系数最后会添加一个0，变成73个系数；但其实这里可以去掉首尾的两个0，系数就成了71个，不过这里无伤大雅，我便没有去除。

接着创建一个LEN长的一维零数组。设定采样率为1000。

##### 验证FIR结构

```python
t = np.linspace(0, 1, fs)
f = np.cos(2*np.pi*10*t) + 2 * np.cos(2*np.pi*3000*t)
# 获取到滤波器，fs/fc = 10：1
coef = set_coef('coef.txt')
# 分配一个fs长的零数组
ret = np.zeros(fs)
# 获取FIR延时加权求和的结果
# 可以选择FIR_INST函数，操作流程直观
# 可以选择FIR_INST_ARRAY函数，选用了数组点乘切片等方式，去掉循环时间应该更快
for i in range(fs):
    ret[i] = fir_inst_array(f[i],coef)
    # ret[i] = fir_inst(f[i],coef)
```

制造一个采样率10000下，振幅为1的10hz正弦波和振幅为2的3000hz正弦波叠加的信号源。接着开始循环，每次循环过程中让信号源数据经过FIR操作后，保存结果。

##### FIR结构实现

```python
def fir_inst(data, coef) :
    # '''
    # :param data: 原始信号 Orignal Signal
    # :param coef: FIR抽头系数数组
    # :return: 滤波之后的信号
    # '''
    ret = 0
    # 加权延时求和操作
    # 第一个抽头和最后的抽头系数一定是0，所以循环只从LEN-1到1
    # 第一个抽头的操作有点不同，它接收进来的data
    for i in range(LEN-1, 0, -1):
        ret = ret + fir_data[i] * coef[i]
        fir_data[i] = fir_data[i-1]
    fir_data[0] = data
    fir_sum_data[0] = fir_data[0] * coef[0]
    return ret
```

这个函数的实现很直观，可以照着这个函数写出C/C++版本。循环中，延时的FIR数据与抽头系数相乘，然后与最终结果累加，整个循环也完成了FIR数据延时一个循环周期的要求。最后还要将新进入的数据保存至FIR数据数组中。

##### FIR结构实现（数组实现方法）

```python
def fir_inst_array(data, coef):
    # '''
    # :param data: 同上 使用数组乘法等规则简化和加快运算过程
    # :param coef:
    # :return:
    # '''
    # FIR_DATA数组使用切片索引等方式实现数组左移并在0位加上新的数据
    fir_data[1:] = fir_data[0:LEN-1]
    fir_data[0] = data
    # 使用数组的点乘获取加权求和的结果
    ret = np.dot(fir_data, coef)
    return ret
```

既然使用了Numpy，肯定有更适合数组运算的方法。在这个函数里面，FIR数据的延时使用切片的方式，使整体数据左移，然后将新加入的数据保存在0位。

FIR数据与抽头系数相乘直接使用了Numpy的点乘，两个数组点乘可以直接得到加权求和的结果。



<<<<<<< HEAD
![结果对比](D:\users\无名\PycharmProjects\data_source\pic\9.png)
=======
![结果对比](https://github.com/maxs-well/FIR_Implementation/blob/master/pic/9.png)
>>>>>>> fir_origin/master

蓝色部分为信号源，橘红色的线就是滤波后的信号。结果表明，滤波器效果已经实现。不过，整个滤波器实现中，我们只是实现了滤波器结构，滤波器系数都是由软件确定。数字信号处理，研究的就是系统冲激响应序列h(n)的确定以及实现。


欢迎关注知乎专栏[Bug记录](https://zhuanlan.zhihu.com/BugRec)

欢迎关注BUG记录公众号（微信号：BugRec），回复106获取本文的Python项目文件夹

![微信号：BugRec](https://github.com/maxs-well/FIR_Implementation/blob/master/pic/1.jpg)


欢迎关注知乎专栏[Bug记录](https://zhuanlan.zhihu.com/BugRec)

欢迎关注BUG记录公众号（微信号：BugRec），回复106获取本文的Python项目文件夹

![微信号：BugRec](D:\users\无名\PycharmProjects\data_source\pic\logo.png)