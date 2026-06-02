using System;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.RegularExpressions;
using Nuke.Common;
using Nuke.Common.IO;
using Nuke.Common.Tooling;
using Nuke.Common.Tools.DotNet;
using Nuke.Common.Tools.Npm;
using ANcpLua.OpenTelemetry.Conventions.Nuke;
using Serilog;
using static Nuke.Common.Tools.DotNet.DotNetTasks;
using static Nuke.Common.Tools.Git.GitTasks;
using static Nuke.Common.Tools.Npm.NpmTasks;

/// <summary>
/// Build entry point for <c>@o-ancpplua/otel-conventions-api</c>.
///
/// Implements <see cref="IDomainConventionsApi"/> by wiring each declarative target
/// to the existing npm scripts in <c>package.json</c> plus the lockstep / determinism
/// policy that this repository owns.
/// </summary>
sealed class Build : NukeBuild, IDomainConventionsApi
{
    // Entry point: default target is the EmitAll aggregate from the component.
    public static int Main() => Execute<Build>(x => ((IDomainConventionsApi)x).EmitAll);

    /// <summary>
    /// Directory containing emitter outputs (<c>Artifacts/emit/{csharp,duckdb,ts-types,lint}</c>).
    /// Overrides the <see cref="IDomainConventionsApi.EmitOutputDir"/> default of <c>./emitters</c>
    /// to keep generated artifacts out of the source-tree <c>emitters/</c> directory
    /// (which holds emitter source code, not outputs).
    /// </summary>
    AbsolutePath IDomainConventionsApi.EmitOutputDir =>
        ((IDomainConventionsApi)this).TryGetValue(() => ((IDomainConventionsApi)this).EmitOutputDir)
        ?? RootDirectory / "Artifacts" / "emit";

    AbsolutePath ArtifactsDir => RootDirectory / "Artifacts";

    // ---------------------------------------------------------------------
    // RestoreTypeSpecDeps: npm ci
    // ---------------------------------------------------------------------
    Target IDomainConventionsApi.RestoreTypeSpecDeps => _ => _
        .Description("Restore npm dependencies (npm ci) for the TypeSpec spec.")
        .Executes(() =>
        {
            NpmCi(s => s.SetProcessWorkingDirectory(((IDomainConventionsApi)this).DomainSpecRoot));
        });

    // ---------------------------------------------------------------------
    // VerifyKeysLockstep: pin assertion + byte-for-byte keys diff
    // ---------------------------------------------------------------------
    Target IDomainConventionsApi.VerifyKeysLockstep => _ => _
        .Description("Assert the resolved upstream keys-package version equals OtelKeysVersion and that generated/otel-keys.gen.tsp matches the package's shipped lib/otel-keys.gen.tsp byte-for-byte. Skips with a warning when the package is not present in node_modules.")
        .DependsOn(((IDomainConventionsApi)this).RestoreTypeSpecDeps)
        .Executes(() =>
        {
            var self = (IDomainConventionsApi)this;
            var spec = self.DomainSpecRoot;
            var pkgName = self.OtelKeysPackage;
            var expected = self.OtelKeysVersion;

            var lockfile = spec / "package-lock.json";
            if (!File.Exists(lockfile))
            {
                throw new InvalidOperationException(
                    $"VerifyKeysLockstep: package-lock.json not found at '{lockfile}'. Run `npm install` first.");
            }

            // Parse package-lock.json and locate the package entry (npm v3 lockfileVersion uses
            // top-level `packages` keyed by install path, with the root entry under "").
            string? resolved = null;
            using (var doc = JsonDocument.Parse(File.ReadAllText(lockfile)))
            {
                if (doc.RootElement.TryGetProperty("packages", out var pkgs))
                {
                    var key = $"node_modules/{pkgName}";
                    if (pkgs.TryGetProperty(key, out var entry)
                        && entry.TryGetProperty("version", out var v))
                    {
                        resolved = v.GetString();
                    }
                }
            }

            if (resolved is null)
            {
                Log.Warning(
                    "VerifyKeysLockstep: upstream keys package '{Pkg}' is not present in package-lock.json. " +
                    "The lockstep flip has not happened yet — skipping pin assertion and keys diff.",
                    pkgName);
                return;
            }

            if (!string.IsNullOrWhiteSpace(expected) && !string.Equals(resolved, expected, StringComparison.Ordinal))
            {
                throw new InvalidOperationException(
                    $"VerifyKeysLockstep: lockfile pins '{pkgName}@{resolved}' but OtelKeysVersion='{expected}'. Exact match required (no semver range tolerance).");
            }

            // Byte-for-byte diff: node_modules/{pkg}/lib/otel-keys.gen.tsp vs generated/otel-keys.gen.tsp.
            var installed = spec / "node_modules" / pkgName / "lib" / "otel-keys.gen.tsp";
            var committed = spec / "generated" / "otel-keys.gen.tsp";

            if (!File.Exists(installed))
            {
                Log.Warning(
                    "VerifyKeysLockstep: '{Installed}' not found — skipping byte diff with '{Committed}'. " +
                    "Once the upstream package is installed this comparison will be enforced.",
                    installed, committed);
                return;
            }

            if (!File.Exists(committed))
            {
                throw new InvalidOperationException(
                    $"VerifyKeysLockstep: committed keys file '{committed}' is missing.");
            }

            var installedBytes = File.ReadAllBytes(installed);
            var committedBytes = File.ReadAllBytes(committed);
            if (!installedBytes.AsSpan().SequenceEqual(committedBytes))
            {
                throw new InvalidOperationException(
                    $"VerifyKeysLockstep: '{committed}' drifted from upstream '{installed}'. Regenerate or pin the matching upstream version.");
            }

            Log.Information(
                "VerifyKeysLockstep: '{Pkg}@{Resolved}' pinned and generated/otel-keys.gen.tsp matches upstream byte-for-byte.",
                pkgName, resolved);
        });

    // ---------------------------------------------------------------------
    // CompileDomainSpec: npm run lint:public (tsp compile index.tsp --no-emit --warn-as-error)
    // ---------------------------------------------------------------------
    Target IDomainConventionsApi.CompileDomainSpec => _ => _
        .Description("Compile the published TypeSpec surface (index.tsp) with --no-emit --warn-as-error via `npm run lint:public`.")
        .DependsOn(((IDomainConventionsApi)this).VerifyKeysLockstep)
        .Executes(() =>
        {
            var spec = ((IDomainConventionsApi)this).DomainSpecRoot;
            NpmRun(s => s
                .SetCommand("lint:public")
                .SetProcessWorkingDirectory(spec));
        });

    // ---------------------------------------------------------------------
    // Per-emitter targets: npx tsp compile main.tsp --emit <emitter> --output-dir <out>
    // ---------------------------------------------------------------------
    Target IDomainConventionsApi.EmitCSharp => _ => _
        .Description("Run the C# TypeSpec emitter into Artifacts/emit/csharp.")
        .DependsOn(((IDomainConventionsApi)this).CompileDomainSpec)
        .Executes(() => RunTypeSpecEmitter("@ancplua/typespec-emit-csharp", "csharp"));

    Target IDomainConventionsApi.EmitDuckDb => _ => _
        .Description("Run the DuckDB TypeSpec emitter into Artifacts/emit/duckdb.")
        .DependsOn(((IDomainConventionsApi)this).CompileDomainSpec)
        .Executes(() => RunTypeSpecEmitter("@ancplua/typespec-emit-duckdb", "duckdb"));

    Target IDomainConventionsApi.EmitTsTypes => _ => _
        .Description("Run the TypeScript-types TypeSpec emitter into Artifacts/emit/ts-types.")
        .DependsOn(((IDomainConventionsApi)this).CompileDomainSpec)
        .Executes(() => RunTypeSpecEmitter("@ancplua/typespec-emit-ts-types", "ts-types"));

    Target IDomainConventionsApi.LintConventions => _ => _
        .Description("Run the ANcpLua conventions linter via `npm run lint` (full-surface compile with --warn-as-error; lint diagnostics live in the @ancplua/typespec-otelconventions-lint TypeSpec library).")
        .DependsOn(((IDomainConventionsApi)this).CompileDomainSpec)
        .Executes(() =>
        {
            var spec = ((IDomainConventionsApi)this).DomainSpecRoot;
            NpmRun(s => s
                .SetCommand("lint")
                .SetProcessWorkingDirectory(spec));
        });

    Target IDomainConventionsApi.EmitAll => _ => _
        .Description("Run all emitters: C#, DuckDB, TypeScript types, and conventions lint.")
        .DependsOn(
            ((IDomainConventionsApi)this).EmitCSharp,
            ((IDomainConventionsApi)this).EmitDuckDb,
            ((IDomainConventionsApi)this).EmitTsTypes,
            ((IDomainConventionsApi)this).LintConventions);

    void RunTypeSpecEmitter(string emitterPackage, string outputSubdir)
    {
        var self = (IDomainConventionsApi)this;
        var spec = self.DomainSpecRoot;
        var outDir = self.EmitOutputDir / outputSubdir;
        EnsureCleanDirectory(outDir);

        // `npm exec --no -- tsp ...` runs the locally-installed TypeSpec compiler
        // without npm attempting to install missing binaries (`--no` is npm's
        // short form of `--no-install`).
        NpmTasks.Npm(
            $"exec --no -- tsp compile main.tsp --emit \"{emitterPackage}\" --output-dir \"{outDir}\"",
            workingDirectory: spec);
    }

    // ---------------------------------------------------------------------
    // VerifyEmitDeterministic: run EmitAll twice into separate scratch dirs and diff.
    // ---------------------------------------------------------------------
    Target IDomainConventionsApi.VerifyEmitDeterministic => _ => _
        .Description("Run every emitter twice into Artifacts/emit-a and Artifacts/emit-b; fail on any byte diff when EmitFailOnDrift is true.")
        .DependsOn(((IDomainConventionsApi)this).VerifyKeysLockstep)
        .Executes(() =>
        {
            var self = (IDomainConventionsApi)this;
            var dirA = ArtifactsDir / "emit-a";
            var dirB = ArtifactsDir / "emit-b";

            RunEmittersInto(dirA);
            RunEmittersInto(dirB);

            var (ok, firstDiff) = DiffDirectoriesBytewise(dirA, dirB);
            if (!ok)
            {
                var msg = $"VerifyEmitDeterministic: drift detected at '{firstDiff}' between '{dirA}' and '{dirB}'.";
                if (self.EmitFailOnDrift)
                {
                    throw new InvalidOperationException(msg);
                }

                Log.Warning("{Msg} (EmitFailOnDrift=false — not failing build.)", msg);
                return;
            }

            Log.Information("VerifyEmitDeterministic: '{A}' and '{B}' are byte-identical across {Count} emitter(s).",
                dirA, dirB, self.Emitters.Length);
        });

    void RunEmittersInto(AbsolutePath root)
    {
        var self = (IDomainConventionsApi)this;
        var spec = self.DomainSpecRoot;
        EnsureCleanDirectory(root);

        // `lint` is a TypeSpec library, not an emitter (no $onEmit); it produces no files,
        // so it has nothing to compare bytewise — exclude it from the determinism check.
        foreach (var emitter in self.Emitters.Where(e => !string.Equals(e, "lint", StringComparison.Ordinal)))
        {
            var (package, subdir) = ResolveEmitter(emitter);
            var outDir = root / subdir;
            EnsureCleanDirectory(outDir);
            NpmTasks.Npm(
                $"exec --no -- tsp compile main.tsp --emit \"{package}\" --output-dir \"{outDir}\"",
                workingDirectory: spec);
        }
    }

    static (string Package, string Subdir) ResolveEmitter(string emitter) => emitter switch
    {
        "csharp" => ("@ancplua/typespec-emit-csharp", "csharp"),
        "duckdb" => ("@ancplua/typespec-emit-duckdb", "duckdb"),
        "ts-types" => ("@ancplua/typespec-emit-ts-types", "ts-types"),
        _ => throw new ArgumentException($"Unknown emitter '{emitter}'. Expected: csharp, duckdb, ts-types (lint is a TypeSpec library, not an emitter).", nameof(emitter)),
    };

    static (bool Ok, string? FirstDiff) DiffDirectoriesBytewise(AbsolutePath a, AbsolutePath b)
    {
        var filesA = Directory.Exists(a)
            ? Directory.GetFiles(a, "*", SearchOption.AllDirectories).Select(p => Path.GetRelativePath(a, p).Replace('\\', '/')).OrderBy(p => p, StringComparer.Ordinal).ToArray()
            : Array.Empty<string>();
        var filesB = Directory.Exists(b)
            ? Directory.GetFiles(b, "*", SearchOption.AllDirectories).Select(p => Path.GetRelativePath(b, p).Replace('\\', '/')).OrderBy(p => p, StringComparer.Ordinal).ToArray()
            : Array.Empty<string>();

        if (!filesA.SequenceEqual(filesB, StringComparer.Ordinal))
        {
            var onlyInA = filesA.Except(filesB, StringComparer.Ordinal).FirstOrDefault();
            var onlyInB = filesB.Except(filesA, StringComparer.Ordinal).FirstOrDefault();
            return (false, onlyInA ?? onlyInB ?? "<file-set differs>");
        }

        foreach (var rel in filesA)
        {
            var bytesA = File.ReadAllBytes(Path.Combine(a, rel));
            var bytesB = File.ReadAllBytes(Path.Combine(b, rel));
            if (!bytesA.AsSpan().SequenceEqual(bytesB))
            {
                return (false, rel);
            }
        }

        return (true, null);
    }

    static void EnsureCleanDirectory(AbsolutePath path)
    {
        if (Directory.Exists(path))
        {
            Directory.Delete(path, recursive: true);
        }
        Directory.CreateDirectory(path);
    }

    // ---------------------------------------------------------------------
    // BuildCSharpEmit: dotnet build the emitted csproj (if any).
    // ---------------------------------------------------------------------
    Target IDomainConventionsApi.BuildCSharpEmit => _ => _
        .Description("dotnet build the emitted C# project under Artifacts/emit/csharp (no-op when no csproj is emitted).")
        .DependsOn(((IDomainConventionsApi)this).EmitCSharp)
        .Executes(() =>
        {
            var self = (IDomainConventionsApi)this;
            var csharpOut = self.EmitOutputDir / "csharp";
            if (!Directory.Exists(csharpOut))
            {
                Log.Warning("BuildCSharpEmit: '{Dir}' does not exist — skipping.", csharpOut);
                return;
            }

            var projects = Directory.GetFiles(csharpOut, "*.csproj", SearchOption.AllDirectories);
            if (projects.Length == 0)
            {
                Log.Warning("BuildCSharpEmit: no *.csproj under '{Dir}' — skipping.", csharpOut);
                return;
            }

            foreach (var csproj in projects)
            {
                DotNetBuild(s => s
                    .SetProjectFile(csproj)
                    .SetConfiguration("Release"));
            }
        });

    // ---------------------------------------------------------------------
    // VerifyNoManualEditsToGenerated: tracked diff + untracked file gap closure.
    // ---------------------------------------------------------------------
    Target IDomainConventionsApi.VerifyNoManualEditsToGenerated => _ => _
        .Description("Fail if anything under generated/ is dirty (tracked diff or untracked file). Closes the Codex untracked-file gap.")
        .Executes(() =>
        {
            var self = (IDomainConventionsApi)this;
            var generated = self.DomainSpecRoot / "generated";

            // Tracked-diff guard: any modified tracked file under generated/.
            Git($"diff --exit-code -- \"{generated}\"", workingDirectory: self.DomainSpecRoot);

            // Untracked-file guard: porcelain output for generated/ must be empty.
            var porcelain = Git($"status --porcelain -- \"{generated}\"", workingDirectory: self.DomainSpecRoot, logOutput: false);
            var dirty = porcelain
                .Select(l => l.Text)
                .Where(l => !string.IsNullOrWhiteSpace(l))
                .ToArray();
            if (dirty.Length > 0)
            {
                throw new InvalidOperationException(
                    $"VerifyNoManualEditsToGenerated: {dirty.Length} untracked or modified file(s) under '{generated}':"
                    + Environment.NewLine
                    + string.Join(Environment.NewLine, dirty));
            }
        });

    // ---------------------------------------------------------------------
    // PackApiPackage: npm pack
    // ---------------------------------------------------------------------
    Target IDomainConventionsApi.PackApiPackage => _ => _
        .Description("Run `npm pack` to validate package.json#files and produce the tarball.")
        .DependsOn(
            ((IDomainConventionsApi)this).VerifyKeysLockstep,
            ((IDomainConventionsApi)this).VerifyEmitDeterministic,
            ((IDomainConventionsApi)this).VerifyNoManualEditsToGenerated,
            ((IDomainConventionsApi)this).CompileDomainSpec)
        .Executes(() =>
        {
            var spec = ((IDomainConventionsApi)this).DomainSpecRoot;
            NpmTasks.Npm("pack", workingDirectory: spec);
        });

    // ---------------------------------------------------------------------
    // PublishApiPackage: npm publish with provenance, mirroring publish.yml dist-tag rules.
    // ---------------------------------------------------------------------
    Target IDomainConventionsApi.PublishApiPackage => _ => _
        .Description("Run `npm publish --access public --provenance --tag <resolved>` using NPM_DIST_TAG (validated against ^[A-Za-z0-9._-]+$).")
        .DependsOn(((IDomainConventionsApi)this).PackApiPackage)
        .Executes(() =>
        {
            var spec = ((IDomainConventionsApi)this).DomainSpecRoot;
            var distTag = ResolveNpmDistTag();
            Log.Information("PublishApiPackage: resolved dist-tag '{Tag}'.", distTag);
            NpmTasks.Npm(
                $"publish --access public --provenance --tag {distTag}",
                workingDirectory: spec);
        });

    static readonly Regex DistTagPattern = new(@"^[A-Za-z0-9._-]+$", RegexOptions.Compiled);

    static string ResolveNpmDistTag()
    {
        // Same resolution rules as .github/workflows/publish.yml:
        //   1. If NPM_DIST_TAG is set explicitly, validate and use it.
        //   2. Otherwise default to "latest" (publish.yml's stable-release default).
        //      Workflow-side prerelease branching lives in the YAML; in local/Nuke usage
        //      callers can pass NPM_DIST_TAG=next themselves.
        var explicitTag = Environment.GetEnvironmentVariable("NPM_DIST_TAG");
        var tag = string.IsNullOrWhiteSpace(explicitTag) ? "latest" : explicitTag.Trim();
        if (!DistTagPattern.IsMatch(tag))
        {
            throw new InvalidOperationException(
                $"PublishApiPackage: invalid npm dist-tag '{tag}' (must match ^[A-Za-z0-9._-]+$).");
        }
        return tag;
    }

    // ---------------------------------------------------------------------
    // PackContractsNuget / PublishContractsNuget: the C# contracts NuGet,
    // mirroring the npm Pack/PublishApiPackage targets. The packaging/ project
    // compiles generated/contracts (gitignored @ancplua/typespec-emit-csharp
    // output) into ANcpLua.OtelConventions.Api, versioned from package.json so
    // the npm and NuGet artifacts stay in lockstep.
    // ---------------------------------------------------------------------
    AbsolutePath PackagingProject => RootDirectory / "packaging" / "ANcpLua.OtelConventions.Api.csproj";
    AbsolutePath NugetOutputDir => ArtifactsDir / "nuget";

    AbsolutePath ContractsEmitDir => ((IDomainConventionsApi)this).DomainSpecRoot / "generated" / "contracts";

    // NuGet-compatible SemVer (MAJOR.MINOR.PATCH[-prerelease]); no build metadata.
    static readonly Regex NugetVersionPattern =
        new(@"^\d+\.\d+\.\d+(-[A-Za-z0-9][A-Za-z0-9.-]*)?$", RegexOptions.Compiled);

    string PackageJsonVersion()
    {
        var pkgJson = ((IDomainConventionsApi)this).DomainSpecRoot / "package.json";
        using var doc = JsonDocument.Parse(File.ReadAllText(pkgJson));
        return doc.RootElement.GetProperty("version").GetString()
            ?? throw new InvalidOperationException($"'{pkgJson}' has no 'version'.");
    }

    // NuGet rejects npm-legal build metadata (e.g. 1.2.3+build.5) and other forms package.json
    // may carry. Strip build metadata and require NuGet-compatible SemVer, so a version that
    // publishes cleanly on npm cannot hard-fail the pack and silently break the npm/NuGet lockstep.
    string NugetPackageVersion()
    {
        var raw = PackageJsonVersion();
        var version = raw.Split('+', 2)[0];
        if (!NugetVersionPattern.IsMatch(version))
            throw new InvalidOperationException(
                $"NugetPackageVersion: package.json version '{raw}' is not NuGet-compatible (expected MAJOR.MINOR.PATCH[-prerelease]).");
        return version;
    }

    // Clean generated/contracts BEFORE EmitCSharp emits into it: the @ancplua/typespec-emit-csharp
    // emitter does not self-clean, so a removed/renamed model would otherwise leave a stale type in
    // the package. Ordered .Before(EmitCSharp) and pulled in via PackContractsNuget's DependsOn, so
    // the plan is CleanContractsEmit -> EmitCSharp -> PackContractsNuget.
    Target CleanContractsEmit => _ => _
        .Unlisted()
        .Before(((IDomainConventionsApi)this).EmitCSharp)
        .Executes(() => ContractsEmitDir.CreateOrCleanDirectory());

    Target PackContractsNuget => _ => _
        .Description("Pack the freshly-emitted C# contracts (generated/contracts) into the ANcpLua.OtelConventions.Api NuGet (versioned from package.json).")
        .DependsOn(CleanContractsEmit, ((IDomainConventionsApi)this).EmitCSharp)
        .Executes(() =>
        {
            // Fail fast rather than ship an empty assembly if the emit produced nothing.
            if (ContractsEmitDir.GlobFiles("**/*.cs").Count == 0)
                throw new InvalidOperationException(
                    $"PackContractsNuget: no *.cs under '{ContractsEmitDir}' after emit — refusing to pack an empty package.");

            NugetOutputDir.CreateOrCleanDirectory();
            DotNetPack(s => s
                .SetProject(PackagingProject)
                .SetConfiguration("Release")
                .SetOutputDirectory(NugetOutputDir)
                .SetVersion(NugetPackageVersion()));
        });

    Target PublishContractsNuget => _ => _
        .Description("Push the ANcpLua.OtelConventions.Api.<version>.nupkg from this pack to the O-ANcppLua GitHub Packages NuGet feed (uses GITHUB_TOKEN).")
        .DependsOn(PackContractsNuget)
        .Executes(() =>
        {
            var token = Environment.GetEnvironmentVariable("GITHUB_TOKEN")
                ?? throw new InvalidOperationException("PublishContractsNuget: GITHUB_TOKEN is required.");
            // Push the exact package produced by this run, not a glob — a wildcard would also
            // upload any stale *.nupkg left in NugetOutputDir on a non-fresh workspace.
            var package = NugetOutputDir / $"ANcpLua.OtelConventions.Api.{NugetPackageVersion()}.nupkg";
            if (!package.FileExists())
                throw new InvalidOperationException($"PublishContractsNuget: expected package '{package}' not found — did PackContractsNuget run?");
            DotNetNuGetPush(s => s
                .SetTargetPath(package)
                .SetSource("https://nuget.pkg.github.com/O-ANcppLua/index.json")
                .SetApiKey(token)
                .EnableSkipDuplicate());
        });

    // ---------------------------------------------------------------------
    // Local "everything green" gate.
    // ---------------------------------------------------------------------
    Target Check => _ => _
        .Description("Local everything-green gate: restore -> lockstep -> compile -> no-manual-edits -> emit-all -> determinism -> npm pack -> C# contracts pack.")
        .DependsOn(
            ((IDomainConventionsApi)this).RestoreTypeSpecDeps,
            ((IDomainConventionsApi)this).VerifyKeysLockstep,
            ((IDomainConventionsApi)this).CompileDomainSpec,
            ((IDomainConventionsApi)this).VerifyNoManualEditsToGenerated,
            ((IDomainConventionsApi)this).EmitAll,
            ((IDomainConventionsApi)this).VerifyEmitDeterministic,
            ((IDomainConventionsApi)this).PackApiPackage,
            PackContractsNuget);
}
