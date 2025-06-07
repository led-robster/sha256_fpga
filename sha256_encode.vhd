-- inspiration : https://github.com/secworks/sha256
-- design adapted by J. Strömbergson
-- memory-like interface implemented with regs

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.pkg_fun.all;



entity sha256_encode is
    port (
        -- clock and reset
        clk     : in std_logic;
        reset   : in std_logic; --active high
        clear   : in std_logic; 
        -- control signals
        run     : in std_logic; -- impulse
        wr      : in std_logic; -- impulse
        wmask   : in unsigned(1 to 512); 
        error   : out std_logic;
        -- data in
        address : in std_logic_vector(0 to 3);
        wdata   : in std_logic_vector(1 to 512);
        -- data out
        valid   : out std_logic; 
        hash    : out std_logic_vector(1 to 256)
    );
end entity sha256_encode;

architecture rtl of sha256_encode is



    -- CONSTANTS
    constant PAD_LIMIT : unsigned(1 to 512) := ( 1 to 447 => '1', others => '0');
    constant ZERO_512 : unsigned(1 to 512) := (others => '0');
    constant MASK_64B : unsigned(1 to 512) := (1 to 448 => '0', others => '1');

    -- FUNCTIONS
    function reverse_any_vector (a: in std_logic_vector)
    return std_logic_vector is
        variable result: std_logic_vector(a'RANGE);
        alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
    begin
        for i in aa'RANGE loop
            result(i) := aa(i);
        end loop;
        return result;
    end; -- function reverse_any_vector
    
    -- TYPES
    type t_regfile is array (0 to 15) of std_logic_vector(1 to 512);
    signal regfile : t_regfile;

    -- SIGNALS

    signal i_wr : std_logic;
    signal i_clear : std_logic;
    signal i_run : std_logic;
    signal o_valid : std_logic;
    signal o_hash : std_logic_vector(1 to 256);

    -- pop_count
    signal pop_count_input : std_logic_vector(1 to 512);
    signal pop_count_result : unsigned(1 to 10);

    -- block processor
    signal H_i : std_logic_vector(1 to 256);
    signal block_i : std_logic_vector(1 to 512);
    signal block_o : std_logic_vector(1 to 256);
    signal block_ready : std_logic;
    signal block_start : std_logic;

    -- internals
    signal highest_addr : std_logic_vector(0 to 3);
    signal ptr_addr : std_logic_vector(0 to 3);
    signal len_in_wmask : unsigned(64 downto 1);
    signal len_in_mask_padded : unsigned(512 downto 1);
    signal wmask_filter : std_logic;
    signal s_error : std_logic;
    signal wr_d : std_logic;
    signal no_pad_ovf : std_logic;
    signal pad_ovf : std_logic;
    signal one_pad_ovf : std_logic;

    --temp
    signal one_bit_append : std_logic_vector(1 to 512);
    signal masked_length : std_logic_vector(1 to 512);
    signal temp2 : std_logic_vector(1 to 512);
    signal temp3 : unsigned(512 downto 1);

begin

    error <= s_error;
    i_wr <= wr;
    i_clear <= clear;
    i_run <= run;
    valid <= o_valid;
    hash <= o_hash;

    pop_count_inst: entity work.pop_count
     generic map(
        N => 512
    )
     port map(
        x => pop_count_input,
        result => pop_count_result
    );


    block_processor_inst: entity work.block_processor
     port map(
        clk => clk,
        reset => reset,
        start => block_start,
        H_i => H_i,
        block_i => block_i,
        ready => block_ready,
        block_o => block_o
    );


    pop_count_input <= std_logic_vector(wmask);
    len_in_wmask <= (pop_count_result'high downto 1 => pop_count_result, others => '0');
    len_in_mask_padded <= ZERO_512(1 to 448) & len_in_wmask;
    masked_length <= std_logic_vector(MASK_64B) and std_logic_vector(len_in_mask_padded);


    -- write process
    wr_proc : process (clk, reset)
        variable temp_slice : unsigned(512 downto 1);
        variable word_length : unsigned(1 to 512);
        variable highest_addr_512b : unsigned(512 downto 1);
    begin

        if reset='1' then
            wmask_filter <= '0';
            highest_addr <= (others => '0');
            wr_d <= '0';
        elsif rising_edge(clk) then

            -- triggers
            no_pad_ovf <= '0';
            pad_ovf <= '0';
            one_pad_ovf <= '0';

            -- delays
            wr_d <= i_wr;

            -- WRITE FEEDBACK CIRCUIT
            if i_wr='1' then
                if wmask=ZERO_512 then
                    regfile(to_integer(unsigned(reverse_any_vector(address)))) <= wdata;
                    if unsigned(reverse_any_vector(address))>unsigned(reverse_any_vector(highest_addr)) then
                        highest_addr <= address;
                    end if;
                else
                    -- wmask='1'
                    wmask_filter <= '1';
                    --
                    regfile(to_integer(unsigned(reverse_any_vector(address)))) <= wdata and std_logic_vector(wmask);

                    if wmask(512)='1' then
                        -- one-padding goes to next location
                        one_pad_ovf <= '1';
                        -- highest_addr <= highest_addr+1;
                    else
                        -- one padding in same location
                        if wmask(447)='1' then
                            -- padding overflow
                            pad_ovf <= '1';
                            highest_addr <= reverse_any_vector(std_logic_vector(unsigned(reverse_any_vector(highest_addr))+1));
                        else
                            -- NO padding overflow -> append
                            no_pad_ovf <= '1';
                        end if;
                    end if;
                    if wmask_filter='1' then
                        -- wmask_filter is high, then discard this write and signal error
                        s_error <= '1';
                    end if;
                end if;
            end if;

            -- WRITE PADDING. happens one cycle after writing the masked block. The WRITE FEEDBACK CIRCUIT has the logic to select which of the three possibilities to run.
            -- possibilities : 
            -- > no_pad_ovf (write in same block because there is available space)
            -- > pad_ovf (write in next block)
            -- > one_pad_ovf (when wdata is 512-bit wide then in next block there will be the full padding)
            if wr_d='1' then
                if no_pad_ovf='1' then
                    highest_addr_512b := (1 => highest_addr(0), 2 => highest_addr(1), 3=> highest_addr(2), 4=> highest_addr(3), others => '0');
                    temp_slice := (len_in_mask_padded + (highest_addr_512b sll 9));
                    regfile(to_integer(unsigned(reverse_any_vector(address)))) <= (wdata and std_logic_vector(wmask)) or ((not std_logic_vector(wmask)) and (std_logic_vector(wmask) srl 1)) or (std_logic_vector(temp_slice));
                end if;
                if pad_ovf='1' then
                    highest_addr_512b := (1 => highest_addr(0), 2 => highest_addr(1), 3=> highest_addr(2), 4=> highest_addr(3), others => '0');
                    temp_slice := (len_in_mask_padded + (highest_addr_512b sll 9));
                    temp3 <= highest_addr_512b;
                    regfile(to_integer(unsigned(reverse_any_vector(address))+1)) <= std_logic_vector(temp_slice);
                    highest_addr <= reverse_any_vector(std_logic_vector(UNSIGNED(reverse_any_vector(address))+1));
                end if;
                if one_pad_ovf='1' then
                    highest_addr_512b := (1 => highest_addr(0), 2 => highest_addr(1), 3=> highest_addr(2), 4=> highest_addr(3), others => '0');
                    temp_slice := (len_in_mask_padded + (highest_addr_512b sll 9));
                    regfile(to_integer(unsigned(reverse_any_vector(address))+1)) <= (1 => '1', 2 to 512 => std_logic_vector(temp_slice(511 downto 1)));
                    highest_addr <= reverse_any_vector(std_logic_vector(UNSIGNED(reverse_any_vector(address))+1));
                end if;
            end if;

            -- clear procedure
            if i_clear='1' then
                -- clear regfile
                regfile <= (others => (others => '0'));
            end if;

        end if;

    end process;

    -- run process
    -- detect run; set H_i=H_0; wait for ready; set H_i=H_o; repeat (highest_addr) times
    run_proc : process (clk, reset)
    begin
        if reset = '1' then

            o_valid <= '0';
            ptr_addr <= (others => '0');
            
        elsif rising_edge(clk) then

            -- triggers
            block_start <= '0';

            -- default
            -- H_i <= block_o;

            if i_run='1' then
                H_i <= H0;
                block_i <= regfile(0);
                ptr_addr <= (others => '0');
                block_start <= '1';
                -- highest_addr <= reverse_any_vector(std_logic_vector(UNSIGNED(reverse_any_vector(highest_addr))-1));
                --
                o_valid <= '0';
            end if;

            if block_ready='1' then
                if ptr_addr=highest_addr then
                    o_hash <= block_o;
                    o_valid <= '1'; 
                else
                    -- highest_addr <= reverse_any_vector(std_logic_vector(UNSIGNED(reverse_any_vector(highest_addr))-1));
                    H_i <= block_o;
                    block_i <= regfile(to_integer(unsigned(reverse_any_vector(ptr_addr))+1));
                    block_start <= '1';
                    ptr_addr <= reverse_any_vector(std_logic_vector(UNSIGNED(reverse_any_vector(ptr_addr))+1));
                end if;
            end if;
            
        end if;
    end process;

    

end architecture;