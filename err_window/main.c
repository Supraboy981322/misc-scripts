#include <gtk/gtk.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char *msg = "unknown error";
char *css_str = "window { background-color: #2e3440; color: #d8dee9; }"
                "button { background-color: #81a1c1; color: black; font-weight: bold; }";

static void activate (
  GtkApplication *app,
  gpointer user_data
) {
  GtkWidget *window;
  GtkWidget *button;
  GtkWidget *err_msg_text;
  GtkWidget *whats_a_div;

  gtk_window_set_title (GTK_WINDOW (window), "err-umm something broke...");
  gtk_window_set_default_size (GTK_WINDOW (window), 200, 200);

  window = gtk_application_window_new(app);
  GtkCssProvider *css = gtk_css_provider_new();
  gtk_css_provider_load_from_string(css, css_str);
  gtk_style_context_add_provider_for_display(
    gdk_display_get_default(),
    GTK_STYLE_PROVIDER (css),
    GTK_STYLE_PROVIDER_PRIORITY_APPLICATION
  );
  whats_a_div = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);

  button = gtk_button_new_with_label("ok");
  err_msg_text = gtk_label_new(msg);


  gtk_widget_set_halign(whats_a_div, GTK_ALIGN_CENTER);
  gtk_widget_set_valign(whats_a_div, GTK_ALIGN_CENTER);
  gtk_widget_set_hexpand(whats_a_div, TRUE);
  gtk_widget_set_vexpand(whats_a_div, TRUE);

  g_signal_connect_swapped (button, "clicked", G_CALLBACK (gtk_window_close), window);

  gtk_box_append(GTK_BOX (whats_a_div), err_msg_text);
  gtk_box_append(GTK_BOX (whats_a_div), button);

  gtk_window_set_child (GTK_WINDOW (window), whats_a_div);

  gtk_window_present (GTK_WINDOW (window));
}

int main (
  int argc,
  char *argv[]
) {
  if (argc > 1) {
    size_t len = strlen(argv[1]) + 1;
    msg = (char *)malloc(len * sizeof(char));

    if (msg == NULL) {
      perror("failed allocate message string");
      return 1;
    }
    strncpy(msg, argv[1], len);
    argv[1][0] = '\0';
    argc = 1;
  } else {
    printf("%d\n", argc);
  }

  GtkApplication *app = gtk_application_new (
    "com.err-umm_something_broke.GtkApplication",
     G_APPLICATION_DEFAULT_FLAGS
  );

  g_signal_connect (app, "activate", G_CALLBACK (activate), NULL);
  //g_object_unref (app);

  return g_application_run (G_APPLICATION (app), argc, argv);;
}
