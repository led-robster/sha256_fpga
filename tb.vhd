-- https://sha256algorithm.com/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.pkg_fun.all;

library std;
use std.env.finish;


entity tb is
end entity tb;

architecture rtl of tb is

    constant T_clk : time := 20 ns;

    signal clk : std_logic := '1';
    signal reset : std_logic := '1';

    signal block_i : std_logic_vector(1 to 512) := (others => '0');
    signal start : std_logic := '0';

    signal buff : std_logic_vector(1 to 512);
    signal bit_idx : integer range 1 to 512;

    -- sha256_encoder
    signal sha256_encode_clear : std_logic;
    signal sha256_encode_run : std_logic;
    signal sha256_encode_wr : std_logic;
    signal sha256_encode_wmask : unsigned(1 to 512);
    signal sha256_encode_address : std_logic_vector(0 to 3);
    signal sha256_encode_wdata : std_logic_vector(1 to 512);
    signal sha256_encode_valid : std_logic;
    signal sha256_encode_hash : std_logic_vector(1 to 256);

    -- simulation
    signal sim_id : positive := 1;


begin

    -- clock process;
    process
    begin
        wait for T_clk/2;
        clk <= not clk;
    end process;

    block_processor_inst: entity work.block_processor(rtl)
    port map(
        clk => clk,
        reset => reset,
        start => start,
        H_i => H0,
        block_i => block_i,
        ready => open,
        block_o => open
    );

    -- ###
    popcount_inst : entity work.pop_count
     generic map(
        N => 8
    )
     port map(
        x => "01011111",
        result => open
    );

    -- ###
    sha256_encode_inst: entity work.sha256_encode
     port map(
        clk => clk,
        reset => reset,
        clear => sha256_encode_clear,
        run => sha256_encode_run,
        wr => sha256_encode_wr,
        wmask => sha256_encode_wmask,
        error => open,
        address => sha256_encode_address,
        wdata => sha256_encode_wdata,
        valid => sha256_encode_valid,
        hash =>  sha256_encode_hash
    );


    main_proc : process
    begin
        buff <= (others => '0');
        sha256_encode_clear <= '0';
        sha256_encode_wr <= '0';
        sha256_encode_address <= (others => '0');
        sha256_encode_wdata <= (others => '0');
        sha256_encode_wmask <= (others => '0');
        sha256_encode_run <= '0';

        wait for 10 * T_clk;

        reset <= '0';
        start <= '1';
        -- spam "H"
        block_i <= x"48484848484848488000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040";

        wait for T_clk;
        start <= '0';

        wait for T_clk;
        wait for 500*T_clk;
        start <= '1';
        block_i <= x"48484848484848488000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040";

        wait for T_clk;
        start <= '0';

        wait for 500*T_clk;
        bit_idx <= 24;
        wait for T_clk;
        buff(1 to bit_idx) <= x"888888";
        wait for T_clk;
        bit_idx <= 12;
        wait for T_clk;
        buff(1 to bit_idx) <= x"444";

        -- TEST PADDING
        -- 1. block 0 with no ovf
        wait for 200*T_clk;
        sha256_encode_wr        <= '1';
        sha256_encode_address   <= (others => '0');
        sha256_encode_wdata     <= (1 to 256 => '1', 257 to 512 => '0');
        sha256_encode_wmask     <= (1 to 8 => '1', others => '0');
        wait for T_clk;
        sha256_encode_wr        <= '0';

        -- reset impulse
        wait for 10*T_clk;
        reset <= '1';
        wait for T_clk;
        reset <= '0';

        -- 2. block 0 with one_ovf
        wait for 10*T_clk;
        sha256_encode_wr        <= '1';
        sha256_encode_address   <= (others => '0');
        sha256_encode_wdata <= x"8A70CA0AE855CFD5311AF48BDC8A8BCA4BF9DB579C67F6D7AE9EAEFBD56431AC01206BC92A4717108E94C87BA4277BE212B1EC1646627D2814C14F82C7E37B0D";
        sha256_encode_wmask     <= (others => '1');
        wait for T_clk;
        sha256_encode_wr        <= '0';

        -- reset impulse
        wait for 10*T_clk;
        reset <= '1';
        wait for T_clk;
        reset <= '0';

        -- 3. block 2 with ovf
        -- [xxx][xxx][xx-][pad]
        sim_id <= 3;
        wait for 10*T_clk;
        sha256_encode_wr        <= '1';
        sha256_encode_address   <= (others => '0');
        sha256_encode_wdata     <= x"8A70CA0AE855CFD5311AF48BDC8A8BCA4BF9DB579C67F6D7AE9EAEFBD56431AC01206BC92A4717108E94C87BA4277BE212B1EC1646627D2814C14F82C7E37B0D";
        sha256_encode_wmask     <= (others => '0');
        wait for T_clk;
        sha256_encode_wr        <= '0';
        wait for T_clk;
        sha256_encode_wr        <= '1';
        sha256_encode_address   <= (0 => '1', others => '0');
        sha256_encode_wdata     <= x"8A70CA0AE855CFD5311AF48BDC8A8BCA4BF9DB579C67F6D7AE9EAEFBD56431AC01206BC92A4717108E94C87BA4277BE212B1EC1646627D2814C14F82C7E37B0D";
        sha256_encode_wmask     <= (others => '0');
        wait for T_clk;
        sha256_encode_wr        <= '0';
        wait for T_clk;
        sha256_encode_wr        <= '1';
        sha256_encode_address   <= (1 => '1', others => '0');
        sha256_encode_wdata     <= x"8A70CA0AE855CFD5311AF48BDC8A8BCA4BF9DB579C67F6D7AE9EAEFBD56431AC01206BC92A4717108E94C87BA4277BE212B1EC1646627D2814C14F82C7E37B0D";
        sha256_encode_wmask     <= (1 to 500 => '1', others => '0');
        wait for T_clk;
        sha256_encode_wr        <= '0';

        -- reset impulse
        wait for 10*T_clk;
        reset <= '1';
        wait for T_clk;
        reset <= '0';

        -- 4. block 2 with no ovf
        sim_id <= 4;
        wait for 10*T_clk;
        sha256_encode_wr        <= '1';
        sha256_encode_address   <= (others => '0');
        sha256_encode_wdata     <= x"8A70CA0AE855CFD5311AF48BDC8A8BCA4BF9DB579C67F6D7AE9EAEFBD56431AC01206BC92A4717108E94C87BA4277BE212B1EC1646627D2814C14F82C7E37B0D";
        sha256_encode_wmask     <= (others => '0');
        wait for T_clk;
        sha256_encode_wr        <= '0';
        wait for T_clk;
        sha256_encode_wr        <= '1';
        sha256_encode_address   <= (0 => '1', others => '0');
        sha256_encode_wdata     <= x"8A70CA0AE855CFD5311AF48BDC8A8BCA4BF9DB579C67F6D7AE9EAEFBD56431AC01206BC92A4717108E94C87BA4277BE212B1EC1646627D2814C14F82C7E37B0D";
        sha256_encode_wmask     <= (others => '0');
        wait for T_clk;
        sha256_encode_wr        <= '0';
        wait for T_clk;
        sha256_encode_wr        <= '1';
        sha256_encode_address   <= (1 => '1', others => '0');
        sha256_encode_wdata     <= x"8A70CA0AE855CFD5311AF48BDC8A8BCA4BF9DB579C67F6D7AE9EAEFBD56431AC01206BC92A4717108E94C87BA4277BE212B1EC1646627D2814C14F82C7E37B0D";
        sha256_encode_wmask     <= (1 to 64 => '1', others => '0');
        wait for T_clk;
        sha256_encode_wr        <= '0';

        -- reset impulse
        wait for 10*T_clk;
        reset <= '1';
        wait for T_clk;
        reset <= '0';

        -- CLEAR FUNC
        sim_id <= 5;
        wait for 10*T_clk;
        sha256_encode_clear <= '1';
        wait for T_clk;
        sha256_encode_clear <= '0';

        -- reset impulse
        wait for 10*T_clk;
        reset <= '1';
        wait for T_clk;
        reset <= '0';


        -- RUN FUNC
        wait for 10*T_clk;
        sha256_encode_wr        <= '1';
        sha256_encode_address   <= (others => '0');
        sha256_encode_wdata     <= x"ABCD0EA0AE855FD5311AF48BDC8A8BCA4BF9DB579C67F6D7AE9EAEFBD56431AC01206BC92A4717108E94C87BA4277BE212B1EC1646627D2814C14F82C7E37B0D";
        sha256_encode_wmask     <= (others => '1');
        wait for T_clk;
        sha256_encode_wr        <= '0';
        wait for T_clk;
        sha256_encode_run       <= '1';
        wait for T_clk;
        sha256_encode_run       <= '0';

        wait until sha256_encode_valid='1';

        if sha256_encode_hash=x"87d76efc45fb304525ec470eec1d5d0b9b20260dc1683a9e62d3c6007cf20114" then
            report "output from encoder matches the model hash. SUCCESS." severity note;
        else
            report "output frome cnodeer soe not match the model hash. FAIL." severity error;
        end if;




        wait for 1000 * T_clk;


        finish;


    end process;



end architecture;