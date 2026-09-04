module UserSerializer
  module_function

  # Nunca expone password_digest.
  def call(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      createdAt: user.created_at
    }
  end
end
