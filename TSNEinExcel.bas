Option Explicit
Function TSNE(XasRange As Range, DesiredPerplexity As Double, Optional numberOfIterations As Long = 1500, Optional numberOfDimentionsInLowDimensionalSpace As Integer = 2, Optional LearningRatio As Double = 100, Optional Momentum As Double = 0.8)
    Randomize
    Dim p() As Variant 'pj|i and later will be pji
    Dim i As Long
    Dim j As Long
    Dim n As Long
    Dim x() As Variant
    Dim numberOfSamplesInX As Long
    Dim numberOfDimentions As Long
    Dim y() As Variant
    Dim oldy() As Variant
    x = XasRange.Value2
    Set XasRange = Nothing
    numberOfSamplesInX = UBound(x, 1)
    numberOfDimentions = UBound(x, 2)
    p = SearchMeForFixedPerpexity(x, numberOfSamplesInX, numberOfDimentions, DesiredPerplexity)
    ReDim y(1 To numberOfSamplesInX, 1 To numberOfDimentionsInLowDimensionalSpace)
    ReDim oldy(1 To numberOfSamplesInX, 1 To numberOfDimentionsInLowDimensionalSpace)
    For i = 1 To numberOfSamplesInX - 1
        For j = i + 1 To numberOfSamplesInX
            p(i)(j) = p(i)(j) / numberOfSamplesInX
        Next j
        For j = 1 To numberOfDimentionsInLowDimensionalSpace
            y(i, j) = Rnd()
        Next j
    Next i
    For j = 1 To numberOfDimentionsInLowDimensionalSpace
        y(numberOfSamplesInX, j) = Rnd()
    Next j
    ''ReDim dCdYi(1 To numberOfSamplesInX, 1 To numberOfDimentionsInLowDimensionalSpace)
    Call YUpload(p, y, oldy, numberOfSamplesInX, numberOfDimentionsInLowDimensionalSpace, 20, Momentum * 0.5, LearningRatio)
    Call YUpload(p, y, oldy, numberOfSamplesInX, numberOfDimentionsInLowDimensionalSpace, numberOfIterations - 20, Momentum, LearningRatio)
    TSNE = y
End Function
Private Function getMeThePairWiseAffinities1(x() As Variant, numberOfSamplesInX As Long, numberOfDimentions As Long)
    'This is the part of the code that is independant of minusTwoSigmaSquared.
    'I can play this part of the code only once during the sigma search
    Dim i As Long
    Dim j As Long
    Dim n As Long
    Dim p() As Variant 'pj|i
    p = GenerateHalfAMatrix(numberOfSamplesInX)
    For i = 1 To numberOfSamplesInX - 1
        For j = i + 1 To numberOfSamplesInX
            For n = 1 To numberOfDimentions
                p(i)(j) = p(i)(j) + (x(i, n) - x(j, n)) ^ 2
            Next n
        Next j
    Next i
    getMeThePairWiseAffinities1 = p
End Function
Private Function getMeThePairWiseAffinities2(aux() As Variant, numberOfSamplesInX As Long, minusTwoSigmaSquared() As Variant)
    '' get the sum of pair wise affinities and the non normilized pair wise affinities
    Dim i As Long
    Dim j As Long
    Dim p() As Variant
    p = aux
    Dim sumOfPairWiseAffinities() As Variant
    ReDim sumOfPairWiseAffinities(1 To numberOfSamplesInX)
    For i = 1 To numberOfSamplesInX - 1
        For j = 1 + i To numberOfSamplesInX
            p(i)(j) = Exp((aux(i)(j)) / minusTwoSigmaSquared(i))
            sumOfPairWiseAffinities(i) = sumOfPairWiseAffinities(i) + p(i)(j)
            sumOfPairWiseAffinities(j) = sumOfPairWiseAffinities(j) + p(i)(j)
        Next j
    Next i
    '' get the normilized pair wise affinities
    For i = 1 To numberOfSamplesInX - 1
        For j = 1 + i To numberOfSamplesInX
            p(i)(j) = p(i)(j) / (sumOfPairWiseAffinities(j) + 0.000001)
        Next j
    Next i
    getMeThePairWiseAffinities2 = p
End Function
Private Function SearchMeForFixedPerpexity(x() As Variant, numberOfSamplesInX As Long, numberOfDimentions As Long, DesiredPerplexity As Double) As Variant
    Dim i As Long
    Dim iter As Long
    Dim top1() As Variant
    ReDim top1(1 To numberOfSamplesInX)
    Dim top2() As Variant
    ReDim top2(1 To numberOfSamplesInX)
    Dim middle1() As Variant
    ReDim middle1(1 To numberOfSamplesInX)
    Dim middle2() As Variant
    ReDim middle2(1 To numberOfSamplesInX)
    Dim bottom1() As Variant
    ReDim bottom1(1 To numberOfSamplesInX)
    Dim bottom2() As Variant
    ReDim bottom2(1 To numberOfSamplesInX)
    Dim p() As Variant 'pj|i
    Dim aux() As Variant
    ReDim aux(1 To numberOfSamplesInX, 1 To numberOfSamplesInX)
    aux = getMeThePairWiseAffinities1(x, numberOfSamplesInX, numberOfDimentions)
    For i = 1 To numberOfSamplesInX
        top1(i) = -50
        bottom1(i) = -1
    Next
    Dim IShouldStay As Boolean
    For iter = 1 To 50
        IShouldStay = True
        p = getMeThePairWiseAffinities2(aux, numberOfSamplesInX, top1)
        top2 = GetMeThePerplexity(p, numberOfSamplesInX)
        For i = 1 To numberOfSamplesInX
            If top2(i) < DesiredPerplexity Then
                IShouldStay = False
                top1(i) = top1(i) * 2
            End If
        Next
        If IShouldStay Then
            Exit For
        End If
    Next
    For iter = 1 To 50
        IShouldStay = True
        p = getMeThePairWiseAffinities2(aux, numberOfSamplesInX, bottom1)
        bottom2 = GetMeThePerplexity(p, numberOfSamplesInX)
        For i = 1 To numberOfSamplesInX
            If bottom2(i) > DesiredPerplexity Then
                IShouldStay = False
                bottom2(i) = bottom2(i) * 0.5
            End If
        Next
        If IShouldStay Then
            Exit For
        End If
    Next
    For i = 1 To numberOfSamplesInX
        middle1(i) = (top1(i) + bottom1(i)) / 2
    Next
    p = getMeThePairWiseAffinities2(aux, numberOfSamplesInX, middle1)
    middle2 = GetMeThePerplexity(p, numberOfSamplesInX)
    For iter = 1 To 100
        For i = 1 To numberOfSamplesInX
            If Abs(middle2(i) - DesiredPerplexity) < 0.01 Or iter = 500 Then
            ElseIf middle2(i) > DesiredPerplexity Then
                top1(i) = middle1(i)
                top2(i) = middle2(i)
                middle1(i) = (top1(i) + bottom1(i)) / 2
            Else
                bottom1(i) = middle1(i)
                bottom2(i) = middle2(i)
                middle1(i) = (top1(i) + bottom1(i)) / 2
            End If
        Next i
        p = getMeThePairWiseAffinities2(aux, numberOfSamplesInX, middle1)
        middle2 = GetMeThePerplexity(p, numberOfSamplesInX)
    Next iter
    SearchMeForFixedPerpexity = p
End Function
Private Function GetMeThePerplexity(p() As Variant, numberOfSamplesInX As Long) As Variant
    Dim Perplexities() As Variant
    ReDim Perplexities(1 To numberOfSamplesInX)
    Dim i As Long
    Dim j As Long
    Dim aux As Double
    For i = 1 To numberOfSamplesInX - 1
        For j = 1 + i To numberOfSamplesInX
            aux = p(i)(j) * WorksheetFunction.Log(p(i)(j) + 0.0001, 2)
            Perplexities(i) = Perplexities(i) + aux
            Perplexities(j) = Perplexities(j) + aux
        Next j
    Next i
    For i = 1 To numberOfSamplesInX
        Perplexities(i) = 2 ^ (-Perplexities(i))
    Next i
    GetMeThePerplexity = Perplexities
End Function
Private Sub YUpload(ByRef p() As Variant, ByRef y() As Variant, ByRef oldy() As Variant, ByRef numberOfSamplesInX As Long, ByRef numberOfDimentionsInLowDimensionalSpace As Integer, ByRef numberOfIterations As Long, ByRef Momentum As Double, LearningRatio As Double)
    Dim aux As Double
    Dim aux1 As Double
    Dim dCdYi() As Variant
    Dim i As Long
    Dim j As Long
    Dim n As Integer
    Dim QZ() As Variant 'Zqji
    QZ = GenerateHalfAMatrix(numberOfSamplesInX)
    Dim iter As Long
    Dim Sumq As Double
    For iter = 1 To numberOfIterations
        ReDim dCdYi(1 To numberOfSamplesInX, 1 To numberOfDimentionsInLowDimensionalSpace)
        For i = 1 To numberOfSamplesInX - 1
            For j = 1 + i To numberOfSamplesInX
                For n = 1 To numberOfDimentionsInLowDimensionalSpace
                    QZ(i)(j) = QZ(i)(j) + (y(i, n) - y(j, n)) ^ 2
                Next n
                QZ(i)(j) = (1 + QZ(i)(j)) ^ -1
                Sumq = Sumq + 2 * QZ(i)(j)
            Next j
        Next i
        For i = 1 To numberOfSamplesInX - 1
            For j = 1 + i To numberOfSamplesInX
                aux = (p(i)(j) - QZ(i)(j) / Sumq) * QZ(i)(j)
                For n = 1 To numberOfDimentionsInLowDimensionalSpace
                    aux1 = aux * (y(i, n) - y(j, n))
                    dCdYi(i, n) = dCdYi(i, n) + aux1
                    dCdYi(j, n) = dCdYi(j, n) - aux1
                Next n
            Next j
        Next i
        For i = 1 To numberOfSamplesInX
            For n = 1 To numberOfDimentionsInLowDimensionalSpace
                aux = y(i, n)
                y(i, n) = y(i, n) - LearningRatio * dCdYi(i, n) + Momentum * (y(i, n) - oldy(i, n))
                oldy(i, n) = aux
            Next n
        Next i
    Next iter
End Sub
Private Function GenerateHalfAMatrix(DimensionA As Variant) As Variant
    Dim aux() As Variant
    Dim p() As Variant
    Dim i As Byte
    Dim j As Byte
    ReDim p(1 To DimensionA - 1)
    For i = 1 To DimensionA - 1
        ReDim aux(i + 1 To DimensionA)
        For j = i + 1 To DimensionA
            aux(j) = 0
        Next j
        p(i) = aux
    Next i
    GenerateHalfAMatrix = p
End Function
