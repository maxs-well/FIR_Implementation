#-*-coding:utf-8-*-
__author__ = 'wood'

import numpy as np
import matplotlib.pyplot as plt

def set_coef(filename):
    # '''
    # :param filename: FIR 抽头系数文件
    # :return:  FIR抽头系数数组
    # '''
    return np.loadtxt(filename)

def coef2function(filename, exp, gain):
    # '''
    # :param filename: FIR抽头系数文件名
    # :param exp:      浮点数转定点数的位宽
    # :param gain:     浮点数整体的增益，增益为power(2, gain)
    # :return:
    # '''
    coef = set_coef(filename)
    with open('fir_coef.v', 'w') as f:
        f.write('function [{}:0] get_coef;\n'.format(exp-1))
        f.write('input [15:0] index;\n')
        f.write('case (index)\n')
        for i in range(len(coef)):
            f.write('{}: get_coef = {};\n'.format(i,int(np.floor(coef[i] * np.power(2,gain)))))
        f.write('default: get_coef = 0;\n')
        f.write('endcase\nendfunction')


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

def float2fix_point(data, exp, gain, size):
    # '''
    # :param data: 信号源数据
    # :param exp:  浮点数转定点数的位宽
    # :param gain: 浮点数整体乘以增益，增益为power(2,15)
    # :param size: 转换多少点数
    # :return:
    # '''
    if size > len(data):
        print("error, size > len(data)")
        return
    data = [int(np.floor(data[i] * np.power(2, gain) )) for i in range(size)]
    fmt = '{{:0>{}b}}'.format(exp)
    n = np.power(2, exp)
    for i in range(size):
        if data[i] > (n //2 - 1):
            print("error")

        if data[i] < 0:
            d = n + data[i]
        else:
            d = data[i]
        data[i] = fmt.format(d)
    # data = [bin(data[i]) for i in range(4096)]
    np.savetxt('cos.txt', data, fmt='%s')

if __name__ == '__main__':
    # FIR抽头阶数
    LEN = 73
    # # FIR滤波器信号数据延时的数组
    fir_data = np.zeros(LEN)
    # 制作一个信号源，对比效果
    # 采样频率
    fs = 10000
    # 制作一个10hz+3000hz的正弦波叠加
    t = np.linspace(0, 7, 7*fs)
    f = np.cos(2*np.pi*10*t) + 2 * np.cos(2*np.pi*3000*t)
    # 获取到滤波器，fs/fc = 10：1
    coef = set_coef('coef.txt')
    # 分配一个fs长的零数组
    ret = np.zeros(fs)
    # 获取FIR延时加权求和的结果
    # 可以选择FIR_INST函数，操作流程直观
    # 可以选择FIR_INST_ARRAY函数，选用了数组点乘切片等方式，去掉循环时间应该更快

    #读取Verilog FIR滤波结果
    data = set_coef('output.txt')
    data = data / max(data)

    for i in range(fs):
        ret[i] = fir_inst_array(f[i],coef)
    #     # ret[i] = fir_inst(f[i],coef)
    # # 保存结果
    np.savetxt('out.txt', ret, fmt='%.6f')
    np.savetxt('signal.txt', f, fmt='%.6f')

    #转换信号源为16位定点数
    float2fix_point(f, 16,13, 64000)

    #转换参数为function
    coef2function('coef.txt',16, 16)

    # plt.plot(data[10000:20000])
    # plt.show()
    # 画个图
    # plt.plot(t,f)
    plt.figure('Python FIR')
    plt.title('Python FIR')
    plt.plot(t[0:10000],ret)
    plt.figure('Verilog FIR')
    plt.title('Verilog FIR')
    plt.plot(t[0:10000],data[0:10000])

    plt.show()