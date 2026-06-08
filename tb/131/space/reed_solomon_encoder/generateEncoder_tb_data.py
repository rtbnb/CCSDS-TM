# License : https://github.com/rtbnb/CCSDS-TM/blob/master/LICENSE

import numpy as np

testDatas = np.linspace(0, 223, 223, dtype=np.uint8)

for testData in testDatas:
    print('inputByte_r <= x"{:x}";'.format(testData))
    print("wait for 10 ns;")
    print("wr_en_i_0_r <= '1';")
    print("wait for 10 ns;")
    print("wr_en_i_0_r <= '0';")
    print("wait for 140 ns;")
    