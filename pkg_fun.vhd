

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;


package pkg_fun is

    constant H0 : std_logic_vector(1 to 256) := x"6A09E667BB67AE853C6EF372A54FF53A510E527F9B05688C1F83D9AB5BE0CD19";

    type matrix is array (1 to 64) of std_logic_vector(1 to 32);

    constant K_TABLE : matrix := (
    x"428A2F98",
    x"71374491",
    x"B5C0FBCF",
    x"E9B5DBA5",
    x"3956C25B",
    x"59F111F1",
    x"923F82A4",
    x"AB1C5ED5",
    x"D807AA98",
    x"12835B01",
    x"243185BE",
    x"550C7DC3",
    x"72BE5D74",
    x"80DEB1FE",
    x"9BDC06A7",
    x"C19BF174",
    x"E49B69C1",
    x"EFBE4786",
    x"0FC19DC6",
    x"240CA1CC",
    x"2DE92C6F",
    x"4A7484AA",
    x"5CB0A9DC",
    x"76F988DA",
    x"983E5152",
    x"A831C66D",
    x"B00327C8",
    x"BF597FC7",
    x"C6E00BF3",
    x"D5A79147",
    x"06CA6351",
    x"14292967",
    x"27B70A85",
    x"2E1B2138",
    x"4D2C6DFC",
    x"53380D13",
    x"650A7354",
    x"766A0ABB",
    x"81C2C92E",
    x"92722C85",
    x"A2BFE8A1",
    x"A81A664B",
    x"C24B8B70",
    x"C76C51A3",
    x"D192E819",
    x"D6990624",
    x"F40E3585",
    x"106AA070",
    x"19A4C116",
    x"1E376C08",
    x"2748774C",
    x"34B0BCB5",
    x"391C0CB3",
    x"4ED8AA4A",
    x"5B9CCA4F",
    x"682E6FF3",
    x"748F82EE",
    x"78A5636F",
    x"84C87814",
    x"8CC70208",
    x"90BEFFFA",
    x"A4506CEB",
    x"BEF9A3F7",
    x"C67178F2"
    );

    function delta_0(
        x : std_logic_vector
    ) return std_logic_vector;

    function delta_1 (
        x : std_logic_vector
    ) return std_logic_vector;

    function sigma_0(
        x : std_logic_vector
    ) return std_logic_vector;

    function sigma_1(
        x : std_logic_vector
    ) return std_logic_vector;

    function H_sum(
        H_o : std_logic_vector(1 to 256);
        H_i : std_logic_vector(1 to 256)
    ) return std_logic_vector;

    -- ============================================================================
    -- 
    -- ============================================================================
    function population_counter(
        x : std_logic_vector
    ) return std_logic_vector;

end package;


package body pkg_fun is
    

    function delta_0 (x : std_logic_vector) return std_logic_vector is
    begin
        return ((x ror 7) xor (x ror 18) xor (x srl 3));
    end function;

    function delta_1 (x : std_logic_vector) return std_logic_vector is
    begin
        return ((x ror 17) xor (x ror 19) xor (x srl 10));
    end function;

    function sigma_0 (x : std_logic_vector) return std_logic_vector is
    begin
        return ((x ror 2) xor (x ror 13) xor (x ror 22));
    end function;

    function sigma_1 (x : std_logic_vector) return std_logic_vector is
    begin
        return ((x ror 6) xor (x ror 11) xor (x ror 25));
    end function;

    function H_sum(H_o : std_logic_vector(1 to 256); H_i : std_logic_vector(1 to 256)) return std_logic_vector is
        variable Ho0, Ho1, Ho2, Ho3, Ho4, Ho5, Ho6, Ho7 : unsigned(1 to 32);
        variable Hi0, Hi1, Hi2, Hi3, Hi4, Hi5, Hi6, Hi7 : unsigned(1 to 32);
    begin
        Ho0 := unsigned(H_o(1 to 32));
        Ho1 := unsigned(H_o(33 to 64));
        Ho2 := unsigned(H_o(65 to 96));
        Ho3 := unsigned(H_o(97 to 128));
        Ho4 := unsigned(H_o(129 to 160));
        Ho5 := unsigned(H_o(161 to 192));
        Ho6 := unsigned(H_o(193 to 224));
        Ho7 := unsigned(H_o(225 to 256));
        Hi0 := unsigned(H_i(1 to 32));
        Hi1 := unsigned(H_i(33 to 64));
        Hi2 := unsigned(H_i(65 to 96));
        Hi3 := unsigned(H_i(97 to 128));
        Hi4 := unsigned(H_i(129 to 160));
        Hi5 := unsigned(H_i(161 to 192));
        Hi6 := unsigned(H_i(193 to 224));
        Hi7 := unsigned(H_i(225 to 256));
        return std_logic_vector((Ho0+Hi0) & (Ho1+Hi1) & (Ho2+Hi2) & (Ho3+Hi3) & (Ho4+Hi4) & (Ho5+Hi5) & (Ho6+Hi6) & (Ho7+Hi7));
    end function;

    -- ============================================================================
    -- works only for masks. 
    -- ============================================================================
    function population_counter(
        x : std_logic_vector
    ) return std_logic_vector is
        variable accumulator : unsigned(x'range);
    begin
        accumulator := (others => '0');
        for ii in x'range loop
            if x(ii)='1' then
                accumulator := to_unsigned(ii,x'high);
            end if;
        end loop;
        return std_logic_vector(accumulator);
    end function;



end package body;