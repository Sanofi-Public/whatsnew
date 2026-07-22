# print_func_diff prints expected diff output

    Code
      print_func_diff(func_cmp, old_version = "1.0.0", new_version = "2.0.0")
    Output
      
      -- Functions --
        Added:
          + new_func(x, y = 1)
        Removed:
          - old_func(a)
        Modified:
          * mod_func
            - 1.0.0: (foo, bar = TRUE)
            + 2.0.0: (foo, bar = FALSE, baz = "new")

