defmodule Rulestead.CodeRefs.ScannerTest do
  use ExUnit.Case, async: true

  alias Rulestead.CodeRefs.Scanner

  @moduletag :tmp_dir

  describe "scan_string/2" do
    test "parses Rulestead.evaluate calls and returns correct line numbers" do
      code = """
      defmodule MyApp.MyModule do
        def my_fun do
          if Rulestead.evaluate(context, "my_flag") do
            :ok
          else
            Rulestead.evaluate(context, "another_flag", default: false)
          end
        end
      end
      """

      assert references = Scanner.scan_string(code, "my_app/my_module.ex")
      assert length(references) == 2

      assert Enum.find(references, &(&1.flag_key == "my_flag")) == %{
               file: "my_app/my_module.ex",
               line: 3,
               flag_key: "my_flag"
             }

      assert Enum.find(references, &(&1.flag_key == "another_flag")) == %{
               file: "my_app/my_module.ex",
               line: 6,
               flag_key: "another_flag"
             }
    end

    test "safely ignores non-matching code without crashing" do
      code = """
      defmodule MyApp.MyModule do
        def my_fun do
          Enum.map([1, 2, 3], &(&1 * 2))
          # Rulestead.evaluate(ctx, "commented_out")
        end
      end
      """

      assert Scanner.scan_string(code, "file.ex") == []
    end

    test "handles syntax errors by ignoring them" do
      code = """
      defmodule MyApp {
        invalid syntax!
      }
      """

      assert Scanner.scan_string(code, "file.ex") == []
    end
  end

  describe "scan_dir/1" do
    test "limits directory traversal to specific paths and files (.ex, .exs)", %{tmp_dir: tmp_dir} do
      # Create some files
      lib_dir = Path.join(tmp_dir, "lib")
      File.mkdir_p!(lib_dir)

      File.write!(Path.join(lib_dir, "a.ex"), "Rulestead.evaluate(ctx, \"flag_a\")")
      File.write!(Path.join(lib_dir, "b.exs"), "Rulestead.evaluate(ctx, \"flag_b\")")
      File.write!(Path.join(lib_dir, "c.txt"), "Rulestead.evaluate(ctx, \"flag_c\")")

      other_dir = Path.join(tmp_dir, "other")
      File.mkdir_p!(other_dir)
      File.write!(Path.join(other_dir, "d.ex"), "Rulestead.evaluate(ctx, \"flag_d\")")

      references = Scanner.scan_dir(lib_dir)

      # Should only pick up .ex and .exs in lib_dir
      assert length(references) == 2

      assert Enum.any?(
               references,
               &(&1.flag_key == "flag_a" and String.ends_with?(&1.file, "a.ex"))
             )

      assert Enum.any?(
               references,
               &(&1.flag_key == "flag_b" and String.ends_with?(&1.file, "b.exs"))
             )

      refute Enum.any?(references, &(&1.flag_key == "flag_c"))
      refute Enum.any?(references, &(&1.flag_key == "flag_d"))
    end
  end
end
