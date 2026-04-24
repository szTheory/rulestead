defmodule RulesteadAdmin.TestSupport.AxeAudit do
  @moduledoc false

  import ExUnit.Assertions

  alias A11yAudit.Assertions, as: A11yAssertions
  alias A11yAudit.Results

  @axe_runner_dir Path.join(System.tmp_dir!(), "rulestead_admin_axe_runner")
  @axe_versions %{
    "axe-core" => "4.11.3",
    "jsdom" => "26.1.0"
  }
  @wcag_tags ["wcag2a", "wcag2aa", "wcag21aa"]
  def assert_accessible!(html) when is_binary(html) do
    html
    |> normalize_html()
    |> run_audit!()
    |> Results.from_json()
    |> A11yAssertions.assert_no_violations()
  end

  defp normalize_html(html) do
    body =
      case Regex.run(~r/<main\b[^>]*class="[^"]*rs-shell__body[^"]*"[^>]*>(.*)<\/main>/s, html) do
        [_, main_html] -> "<main class=\"rs-shell__body\">#{main_html}</main>"
        _ -> html
      end

    """
    <!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <title>Rulestead Admin Accessibility Audit</title>
      </head>
      <body>
        #{body}
      </body>
    </html>
    """
  end

  defp run_audit!(html) do
    html_path = write_html!(html)

    ensure_runner_packages!()

    {output, exit_code} =
      System.cmd(
        "node",
        ["axe_runner.js", html_path],
        cd: @axe_runner_dir,
        stderr_to_stdout: true,
        env: [{"RULESTEAD_AXE_TAGS", Enum.join(@wcag_tags, ",")}]
      )

    File.rm(html_path)

    assert exit_code == 0,
           "axe runner exited with #{exit_code}:\n#{output}"

    Jason.decode!(output)
  end

  defp write_html!(html) do
    path =
      Path.join(
        System.tmp_dir!(),
        "rulestead-admin-axe-#{System.unique_integer([:positive])}.html"
      )

    File.write!(path, html)
    path
  end

  defp ensure_runner_packages! do
    File.mkdir_p!(@axe_runner_dir)
    write_package_json!()
    write_runner_script!()

    unless File.exists?(Path.join(@axe_runner_dir, "node_modules/axe-core/package.json")) and
             File.exists?(Path.join(@axe_runner_dir, "node_modules/jsdom/package.json")) do
      {output, exit_code} =
        System.cmd(
          "npm",
          [
            "install",
            "--no-package-lock",
            "--no-save",
            "axe-core@#{@axe_versions["axe-core"]}",
            "jsdom@#{@axe_versions["jsdom"]}"
          ],
          cd: @axe_runner_dir,
          stderr_to_stdout: true
        )

      assert exit_code == 0,
             "failed to install axe runner packages:\n#{output}"
    end
  end

  defp write_package_json! do
    File.write!(
      Path.join(@axe_runner_dir, "package.json"),
      ~s({"name":"rulestead-admin-axe-runner","private":true})
    )
  end

  defp write_runner_script! do
    File.write!(Path.join(@axe_runner_dir, "axe_runner.js"), runner_script())
  end

  defp runner_script do
    """
    const fs = require("fs");
    const path = process.argv[2];
    const { JSDOM } = require("jsdom");

    const html = fs.readFileSync(path, "utf8");
    const tags = (process.env.RULESTEAD_AXE_TAGS || "")
      .split(",")
      .map((tag) => tag.trim())
      .filter(Boolean);

    const dom = new JSDOM(html, {
      runScripts: "outside-only",
      url: "http://localhost/"
    });

    global.window = dom.window;
    global.document = dom.window.document;
    global.Node = dom.window.Node;
    global.Document = dom.window.Document;
    global.Element = dom.window.Element;
    global.HTMLElement = dom.window.HTMLElement;
    global.navigator = dom.window.navigator;
    global.getComputedStyle = dom.window.getComputedStyle;
    global.requestAnimationFrame = dom.window.requestAnimationFrame;
    global.cancelAnimationFrame = dom.window.cancelAnimationFrame;
    const axe = require("axe-core");

    axe
      .run(dom.window.document, {
        runOnly: { type: "tag", values: tags },
        rules: {
          "color-contrast": { enabled: false }
        }
      })
      .then((result) => {
        process.stdout.write(JSON.stringify(result));
      })
      .catch((error) => {
        process.stderr.write(String(error));
        process.exit(1);
      });
    """
  end
end
