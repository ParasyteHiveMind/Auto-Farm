PlaceTowerInArea(x1, y1, x2, y2, gapx := 30, gapy := 30)
{
    if (ShouldStop())
        return

    MoveMouseSeguro(x1, y1)
    if (SleepComChecagem(100) != "OK")
        return

    ClickX := x1
    While (ClickX <= x2)
    {
        if (ShouldStop())
            return

        ClickY := y1
        While (ClickY <= y2)
        {
            if (ShouldStop())
                return

            Click, %ClickX%, %ClickY%, 0
            Click

            if (SleepComChecagem(150) != "OK")
                return

            ClickY += gapy
        }
        ClickX += gapx
    }

    SleepComChecagem(100)
}
