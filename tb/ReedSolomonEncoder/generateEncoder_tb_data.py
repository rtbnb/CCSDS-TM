import numpy as np

testDatas = np.linspace(0, 223, 223, dtype=np.uint8)

for testData in testDatas:
    print('inputByte_r <= x"{:x}";'.format(testData))
    print("wait for 160 ns;")