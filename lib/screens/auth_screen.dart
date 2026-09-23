import 'package:flutter/material.dart';

import 'task_list_screen.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _hidePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _selectMode(bool isLogin) {
    setState(() {
      _isLogin = isLogin;
      _hidePassword = true;
    });
    _formKey.currentState?.reset();
    _passwordController.clear();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const TaskListPage(logoutDestination: AuthPage()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _WarehouseHeader(),
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x160F172A),
                                blurRadius: 28,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AuthModeSwitcher(
                                  isLogin: _isLogin,
                                  onChanged: _selectMode,
                                ),
                                const SizedBox(height: 26),
                                Text(
                                  _isLogin
                                      ? 'Вход в систему'
                                      : 'Регистрация сотрудника',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF172033),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isLogin
                                      ? 'Введите данные своей учётной записи'
                                      : 'Придумайте логин и пароль',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 26),
                                const Text(
                                  'Логин',
                                  style: TextStyle(
                                    color: Color(0xFF374151),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    hintText: 'Введите логин',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Введите логин';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Пароль',
                                  style: TextStyle(
                                    color: Color(0xFF374151),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _hidePassword,
                                  textInputAction: _isLogin
                                      ? TextInputAction.done
                                      : TextInputAction.next,
                                  onFieldSubmitted: _isLogin
                                      ? (_) => _submit()
                                      : null,
                                  decoration: InputDecoration(
                                    hintText: 'Введите пароль',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _hidePassword = !_hidePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _hidePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Введите пароль';
                                    }
                                    return null;
                                  },
                                ),
                                if (!_isLogin) ...[
                                  const SizedBox(height: 18),
                                  const Text(
                                    'Повторите пароль',
                                    style: TextStyle(
                                      color: Color(0xFF374151),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    obscureText: _hidePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: const InputDecoration(
                                      hintText: 'Введите пароль ещё раз',
                                      prefixIcon: Icon(
                                        Icons.lock_reset_rounded,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Повторите пароль';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Пароли не совпадают';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                                const SizedBox(height: 26),
                                SizedBox(
                                  height: 54,
                                  child: FilledButton(
                                    onPressed: _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF3157D5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: Text(
                                      _isLogin ? 'Войти' : 'Зарегистрироваться',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WarehouseHeader extends StatelessWidget {
  const _WarehouseHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: const Color(0xFF3157D5),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.warehouse_outlined,
            color: Colors.white,
            size: 42,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'SmartTaskHandler',
          style: TextStyle(
            color: Color(0xFF172033),
            fontSize: 27,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Управление складскими задачами',
          style: TextStyle(color: Color(0xFF667085), fontSize: 14),
        ),
      ],
    );
  }
}

class _AuthModeSwitcher extends StatelessWidget {
  const _AuthModeSwitcher({required this.isLogin, required this.onChanged});

  final bool isLogin;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              text: 'Вход',
              selected: isLogin,
              onPressed: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ModeButton(
              text: 'Регистрация',
              selected: !isLogin,
              onPressed: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.text,
    required this.selected,
    required this.onPressed,
  });

  final String text;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF3157D5)
                  : const Color(0xFF6B7280),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
