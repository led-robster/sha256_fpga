-- purely combinatorial
-- maximum plaintext length = 100 characters = 800 bits , end of word delimited by 0x04 (ETX), real input is 808 bits
-- ["ciao"|0x04|0x0000****000]
-- https://www.reddit.com/r/FPGA/comments/avztn0/synthesizable_modulo_operator/


-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;
-- use ieee.math_real.all;


-- library work;


-- entity padding is
--     port (
--         plaintext   : in std_logic_vector;
--         plainMSB    
--         length      : in unsigned(1 to 800);
--         z_vector    : in std_logic_vector(1 to 512);
--         paddedtext  : out std_logic_vector(1 to 1024)
--     );
-- end entity padding;

-- architecture rtl of padding is


-- begin

--     paddedtext <= plaintext(1 to plainMSB) & '1' & zeros(1 to zMSB) & length, others => '0');

--     process (plaintext)
--         variable k : integer;
--         variable zeros : std_logic_vector(1 to k);
--     begin
--         k := to_integer(unsigned((std_logic_vector(to_unsigned(447 - to_integer(length),9)) and b"111111111")));
--         zeros := (others => '0');
--         paddedtext <= ;
--         --k_int <= k;
--     end process;

--     tb_process: process
--     begin
--         report "padded length : " & integer'image(paddedtext'length);
--         wait for 1000 ms;
--     end process;
    

-- end architecture;