import type { Program, Scalar, Type } from "@typespec/compiler";
import { isArrayModelType, isRecordModelType, getFormat } from "@typespec/compiler";
import { getCsharpNamespace } from "./decorators.js";
import { reportDiagnostic } from "./lib.js";

const SCALAR_MAP: Record<string, string> = {
  "int8": "sbyte",
  "int16": "short",
  "int32": "int",
  "int64": "long",
  "uint8": "byte",
  "uint16": "ushort",
  "uint32": "uint",
  "uint64": "ulong",
  "float32": "float",
  "float64": "double",
  "decimal": "decimal",
  "decimal128": "decimal",
  "boolean": "bool",
  "bytes": "ReadOnlyMemory<byte>",
  "utcDateTime": "DateTimeOffset",
  "offsetDateTime": "DateTimeOffset",
  "plainDate": "DateOnly",
  "plainTime": "TimeOnly",
  "duration": "TimeSpan",
  "url": "Uri",
};

export function mapType(program: Program, type: Type): string {
  switch (type.kind) {
    case "Scalar":
      return mapScalar(program, type as Scalar);
    case "Model":
      if (isArrayModelType(type)) {
        const inner = mapType(program, type.indexer!.value);
        return `IReadOnlyList<${inner}>`;
      }
      if (isRecordModelType(type)) {
        const inner = mapType(program, type.indexer!.value);
        return `IReadOnlyDictionary<string, ${inner}>`;
      }
      return qualifyModelOrEnum(program, type);
    case "Enum":
      return qualifyModelOrEnum(program, type);
    case "ModelProperty":
      // TypeSpec 1.13 constraint-based member access (e.g. `P.id`): the property
      // reference stands for the referenced property's type.
      return mapType(program, (type as { type: Type }).type);
    case "EnumMember":
      return qualifyModelOrEnum(program, (type as { enum: Type }).enum);
    case "Union":
      // TypeSpec unions don't have a clean C# equivalent. Named unions (e.g. LogBody,
      // AttributeValue) aren't emitted as separate types; flatten to object so the property
      // accepts any JSON-compatible value. Downstream JSON serialization preserves type info
      // via STJ's object handling. Literal-string unions (e.g. "a" | "b") fall through to
      // string via the String case above; only named unions hit this branch.
      return "object";
    case "Boolean":
      return "bool";
    case "String":
      return "string";
    case "Number":
      return "double";
    case "Intrinsic":
      if ((type as { name?: string }).name === "null") return "null";
      if ((type as { name?: string }).name === "unknown") return "object";
      if ((type as { name?: string }).name === "void") return "void";
      if ((type as { name?: string }).name === "never") return "void";
      reportDiagnostic(program, { code: "unmapped-type", target: type, format: { name: `intrinsic:${(type as { name?: string }).name ?? "?"}` } });
      return "object";
    default:
      reportDiagnostic(program, { code: "unmapped-type", target: type, format: { name: type.kind } });
      return "object";
  }
}

function mapScalar(program: Program, scalar: Scalar): string {
  if (scalar.name === "string") {
    const format = getFormat(program, scalar as unknown as Parameters<typeof getFormat>[1]);
    if (format === "uuid") return "Guid";
    if (format === "url" || format === "uri") return "Uri";
    return "string";
  }
  const direct = SCALAR_MAP[scalar.name];
  if (direct) return direct;
  if (scalar.baseScalar) return mapScalar(program, scalar.baseScalar);
  reportDiagnostic(program, { code: "unmapped-type", target: scalar, format: { name: `scalar:${scalar.name}` } });
  return "object";
}

function qualifyModelOrEnum(program: Program, type: Type): string {
  const asModel = type as { name?: string; templateMapper?: { args: readonly Type[] } };
  let name = asModel.name ?? "object";
  if (asModel.templateMapper?.args?.length) {
    // Templated model: use the instantiated name (`CursorPageTrace`) so it matches the
    // name the emitter produces for the type declaration.
    const parts = [name];
    for (const arg of asModel.templateMapper.args) {
      if ("name" in arg && typeof (arg as { name?: string }).name === "string") {
        parts.push(pascal((arg as { name: string }).name));
      }
    }
    name = parts.join("");
  }
  const ownNs = getCsharpNamespace(program, type);
  if (ownNs) return `${ownNs}.${name}`;
  const parentNs = climbForNamespace(program, type);
  return parentNs ? `${parentNs}.${name}` : name;
}

function pascal(s: string): string {
  return s.length === 0 ? s : s[0].toUpperCase() + s.slice(1);
}

function climbForNamespace(program: Program, type: Type): string | undefined {
  let cursor: { namespace?: { name?: string } & { namespace?: unknown } } | undefined =
    type as { namespace?: { name?: string } & { namespace?: unknown } };
  while (cursor?.namespace) {
    const ns = cursor.namespace as unknown as Type;
    const mapped = getCsharpNamespace(program, ns);
    if (mapped) return mapped;
    cursor = ns as unknown as typeof cursor;
  }
  return undefined;
}
