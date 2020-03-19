#-*-coding:utf-8-*-
__author__ = 'wood'

import numpy as np
import matplotlib.pyplot as plt

def set_coef(filename):
    # '''
    # :param filename: FIR ��ͷϵ���ļ�
    # :return:  FIR��ͷϵ������
    # '''
    return np.loadtxt(filename)

def coef2function(filename, exp, gain):
    # '''
    # :param filename: FIR��ͷϵ���ļ���
    # :param exp:      ������ת��������λ��
    # :param gain:     ��������������棬����Ϊpower(2, gain)
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
    # :param data: ԭʼ�ź� Orignal Signal
    # :param coef: FIR��ͷϵ������
    # :return: �˲�֮����ź�
    # '''
    ret = 0
    # ��Ȩ��ʱ��Ͳ���
    # ��һ����ͷ�����ĳ�ͷϵ��һ����0������ѭ��ֻ��LEN-1��1
    # ��һ����ͷ�Ĳ����е㲻ͬ�������ս�����data
    for i in range(LEN-1, 0, -1):
        ret = ret + fir_data[i] * coef[i]
        fir_data[i] = fir_data[i-1]
    fir_data[0] = data
    fir_sum_data[0] = fir_data[0] * coef[0]

    return ret

def fir_inst_array(data, coef):
    # '''
    # :param data: ͬ�� ʹ������˷��ȹ���򻯺ͼӿ��������
    # :param coef:
    # :return:
    # '''
    # FIR_DATA����ʹ����Ƭ�����ȷ�ʽʵ���������Ʋ���0λ�����µ�����
    fir_data[1:] = fir_data[0:LEN-1]
    fir_data[0] = data
    # ʹ������ĵ�˻�ȡ��Ȩ��͵Ľ��
    ret = np.dot(fir_data, coef)
    return ret

def float2fix_point(data, exp, gain, size):
    # '''
    # :param data: �ź�Դ����
    # :param exp:  ������ת��������λ��
    # :param gain: ����������������棬����Ϊpower(2,15)
    # :param size: ת�����ٵ���
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
    # FIR��ͷ����
    LEN = 73
    # # FIR�˲����ź�������ʱ������
    fir_data = np.zeros(LEN)
    # ����һ���ź�Դ���Ա�Ч��
    # ����Ƶ��
    fs = 10000
    # ����һ��10hz+3000hz�����Ҳ�����
    t = np.linspace(0, 7, 7*fs)
    f = np.cos(2*np.pi*10*t) + 2 * np.cos(2*np.pi*3000*t)
    # ��ȡ���˲�����fs/fc = 10��1
    coef = set_coef('coef.txt')
    # ����һ��fs����������
    ret = np.zeros(fs)
    # ��ȡFIR��ʱ��Ȩ��͵Ľ��
    # ����ѡ��FIR_INST��������������ֱ��
    # ����ѡ��FIR_INST_ARRAY������ѡ������������Ƭ�ȷ�ʽ��ȥ��ѭ��ʱ��Ӧ�ø���

    #��ȡVerilog FIR�˲����
    data = set_coef('output.txt')
    data = data / max(data)

    for i in range(fs):
        ret[i] = fir_inst_array(f[i],coef)
    #     # ret[i] = fir_inst(f[i],coef)
    # # ������
    np.savetxt('out.txt', ret, fmt='%.6f')
    np.savetxt('signal.txt', f, fmt='%.6f')

    #ת���ź�ԴΪ16λ������
    float2fix_point(f, 16,13, 64000)

    #ת������Ϊfunction
    coef2function('coef.txt',16, 16)

    # plt.plot(data[10000:20000])
    # plt.show()
    # ����ͼ
    # plt.plot(t,f)
    plt.figure('Python FIR')
    plt.title('Python FIR')
    plt.plot(t[0:10000],ret)
    plt.figure('Verilog FIR')
    plt.title('Verilog FIR')
    plt.plot(t[0:10000],data[0:10000])

    plt.show()