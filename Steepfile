D = Steep::Diagnostic

target :lib do
  signature "sig"

  configure_code_diagnostics do |hash|
    hash[D::Ruby::ImplicitBreakValueMismatch] = :hint
    hash[D::Ruby::ElseOnExhaustiveCase] = :hint
  end

  check "lib/lrama/"
end
