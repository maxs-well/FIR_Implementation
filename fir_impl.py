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

if __name__ == '__main__':
    # FIR��ͷ����
    LEN = 73
    # FIR�˲����ź�������ʱ������
    fir_data = np.zeros(LEN)
    # ����һ���ź�Դ���Ա�Ч��
    # ����Ƶ��
    fs = 10000
    # ����һ��10hz+3000hz�����Ҳ�����
    t = np.linspace(0, 1, fs)
    f = np.cos(2*np.pi*10*t) + 2 * np.cos(2*np.pi*3000*t)
    # ��ȡ���˲�����fs/fc = 10��1
    coef = set_coef('coef.txt')
    # ����һ��fs����������
    ret = np.zeros(fs)
    # ��ȡFIR��ʱ��Ȩ��͵Ľ��
    # ����ѡ��FIR_INST��������������ֱ��
    # ����ѡ��FIR_INST_ARRAY������ѡ������������Ƭ�ȷ�ʽ��ȥ��ѭ��ʱ��Ӧ�ø���
    for i in range(fs):
        ret[i] = fir_inst_array(f[i],coef)
        # ret[i] = fir_inst(f[i],coef)
    # ������
    np.savetxt('out.txt', ret, fmt='%.6f')
    np.savetxt('signal.txt', f, fmt='%.6f')

    # ����ͼ
    plt.plot(t,f)
    plt.plot(t,ret)
    plt.show()