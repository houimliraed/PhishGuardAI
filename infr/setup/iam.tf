# iam for the deployement user

resource "aws_iam_user" "cd" {
  name = "devops-cd"
}
resource "aws_iam_access_key" "cd" {
  user = aws_iam_user.cd.name
}