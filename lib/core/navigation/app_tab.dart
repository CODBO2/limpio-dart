enum AppTab { balance, actividad, topicos, tarjetas, papelera }

extension AppTabIndex on AppTab {
  int get tabIndex => index;
}
